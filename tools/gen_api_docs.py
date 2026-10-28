#!/usr/bin/env python3
"""Generate Markdown API reference pages from DDoc comments.

Runs `dmd -D` with tools/markdown.ddoc so the compiler emits Markdown instead
of HTML. Pages land in docs/api/ (gitignored) and get rendered natively by
Zensical. Also refreshes the API section of the `nav` table in zensical.toml,
between the `# api-nav-begin` / `# api-nav-end` markers.

Usage: python3 tools/gen_api_docs.py
Requires: dmd, dub.
"""

import html
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "source" / "selenium"
THEME = ROOT / "tools" / "markdown.ddoc"
OUT_DIR = ROOT / "docs" / "api"
ZENSICAL_TOML = ROOT / "zensical.toml"
NAV_BEGIN = "# api-nav-begin"
NAV_END = "# api-nav-end"

MODULE_RE = re.compile(r"^\s*module\s+([a-zA-Z_][\w.]*)\s*;", re.MULTILINE)


def import_paths() -> list[str]:
    """Absolute -I paths for this package and its dependencies, via dub."""
    desc = json.loads(
        subprocess.run(
            ["dub", "describe"], cwd=ROOT, check=True, capture_output=True, text=True
        ).stdout
    )
    paths = {
        str(Path(p["path"], ip).resolve())
        for p in desc["packages"]
        for ip in p.get("importPaths", [])
    }
    return sorted(paths)


def module_name(path: Path) -> str:
    m = MODULE_RE.search(path.read_text())
    if not m:
        sys.exit(f"error: no module declaration in {path}")
    return m.group(1)


def module_summary(path: Path) -> str:
    """First line of the /// doc comment above the module declaration."""
    lines = path.read_text().splitlines()
    for i, line in enumerate(lines):
        if MODULE_RE.match(line):
            j = i - 1
            comment: list[str] = []
            while j >= 0 and (text := lines[j].strip()).startswith("///"):
                comment.append(text[3:].strip())
                j -= 1
            return next((c for c in comment if c), "")
    return ""


FENCE_RE = re.compile(r"^```")
AUTOLINK_RE = re.compile(r"<([a-zA-Z][a-zA-Z0-9+.-]*:[^>\s]*)>")


def unescape_fences(text: str) -> str:
    """HTML-unescape inside fenced code blocks only."""
    out, in_fence = [], False
    for line in text.splitlines():
        if FENCE_RE.match(line):
            in_fence = not in_fence
        out.append(html.unescape(line) if in_fence else line)
    return "\n".join(out)


def escape_prose(text: str) -> str:
    """Fix entities outside fenced code blocks.

    dmd escapes HTML entities inside code spans but not in prose, so inline
    code is unescaped while raw `&`/`<` in prose is escaped. Autolinks of the
    form <scheme:...> emitted by the ddoc theme are kept."""
    out, in_fence = [], False
    for line in text.splitlines():
        if FENCE_RE.match(line):
            in_fence = not in_fence
            out.append(line)
            continue
        if in_fence:
            out.append(line)
            continue

        stash: list[str] = []

        def keep(m: re.Match) -> str:
            stash.append(m.group(0))
            return f"\x00{len(stash) - 1}\x00"

        line = re.sub(r"`[^`]*`", lambda m: stash.append(html.unescape(m.group(0))) or f"\x00{len(stash) - 1}\x00", line)
        line = AUTOLINK_RE.sub(keep, line)
        line = re.sub(r"&(?!#?\w+;)", "&amp;", line).replace("<", "&lt;")
        out.append(re.sub(r"\x00(\d+)\x00", lambda m: stash[int(m.group(1))], line))
    return "\n".join(out)


def tidy(text: str) -> str:
    return re.sub(r"\n{3,}", "\n\n", text).strip() + "\n"


def generate_page(dfile: Path, imports: list[str]) -> tuple[str, Path]:
    fqn = module_name(dfile)
    out = OUT_DIR / f"{fqn}.md"
    subprocess.run(
        ["dmd", "-o-", "-D", f"-Df{out}", *imports, str(dfile), str(THEME)],
        cwd=ROOT,
        check=True,
    )
    out.write_text(tidy(escape_prose(unescape_fences(out.read_text()))))
    return fqn, out


def index_page(modules: dict[str, str]) -> str:
    """modules: fqn -> one-line summary. Grouped by package."""
    groups: dict[str, list[str]] = {}
    for fqn in modules:
        pkg = fqn.rpartition(".")[0] or fqn
        groups.setdefault(pkg, []).append(fqn)

    lines = [
        "# API Reference",
        "",
        "Generated from the D source's [DDoc](https://dlang.org/spec/ddoc.html) comments.",
        "",
    ]
    for pkg in sorted(groups):
        lines += [f"## `{pkg}`", "", "| Module | Description |", "| ------ | ----------- |"]
        for fqn in sorted(groups[pkg]):
            summary = html.escape(modules[fqn], quote=False)
            lines.append(f"| [`{fqn}`]({fqn}.md) | {summary} |")
        lines.append("")
    return "\n".join(lines)


def nav_entries(modules: dict[str, str], indent: str = "    ") -> str:
    """TOML nav entries for api pages, nested by package.

    e.g. selenium.browser.chrome -> { "browser" = [..., "api/selenium.browser.md",
    "api/selenium.browser.chrome.md", ...] } inside the API Reference section."""
    packages = {fqn for fqn in modules if any(m != fqn and m.startswith(fqn + ".") for m in modules)}

    def group_path(fqn: str) -> list[str]:
        parts = fqn.split(".")[1:]  # drop the 'selenium' prefix
        return parts if fqn in packages else parts[:-1]

    def emit(path: list[str], level: int) -> list[str]:
        pad = "  " * level + indent
        lines = [f'{pad}"api/{fqn}.md",' for fqn in sorted(modules) if group_path(fqn) == path]
        children = sorted(
            {p[len(path)] for m in modules for p in [group_path(m)]
             if len(p) > len(path) and p[:len(path)] == path}
        )
        for child in children:
            lines.append(f'{pad}{{ "{child}" = [')
            lines += emit(path + [child], level + 1)
            lines.append(f"{pad}] }},")
        return lines

    return "\n".join(emit([], 0))


def update_nav(modules: dict[str, str]) -> None:
    toml = ZENSICAL_TOML.read_text()
    if NAV_BEGIN not in toml or NAV_END not in toml:
        sys.exit(f"error: {ZENSICAL_TOML.name} is missing the {NAV_BEGIN} / {NAV_END} markers")

    block = (
        f"{NAV_BEGIN}\n"
        '  { "API Reference" = [\n'
        '    "api/index.md",\n'
        f"{nav_entries(modules)}\n"
        "  ] },\n"
        f"  {NAV_END}"
    )
    toml = re.sub(
        rf"{re.escape(NAV_BEGIN)}.*?{re.escape(NAV_END)}", lambda _: block, toml, flags=re.DOTALL
    )
    ZENSICAL_TOML.write_text(toml)


def main() -> None:
    dfiles = sorted(SRC_DIR.rglob("*.d"))
    if not dfiles:
        sys.exit(f"error: no sources under {SRC_DIR}")
    imports = [f"-I{p}" for p in import_paths()]
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    modules: dict[str, str] = {}
    for dfile in dfiles:
        fqn, out = generate_page(dfile, imports)
        modules[fqn] = module_summary(dfile)
        print(f"  {out.relative_to(ROOT)}")

    (OUT_DIR / "index.md").write_text(index_page(modules))
    print(f"  {(OUT_DIR / 'index.md').relative_to(ROOT)}")

    update_nav(modules)
    print(f"updated nav in {ZENSICAL_TOML.name}")


if __name__ == "__main__":
    main()
