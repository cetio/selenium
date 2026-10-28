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
SCOPE_ENTER = "@@ddoc-enter@@"
SCOPE_LEAVE = "@@ddoc-leave@@"
MEMBER_ENTER = "@@member-enter@@"
MEMBER_LEAVE = "@@member-leave@@"
MEMBER_DIV = '<div class="member" markdown="1">'
ANCHOR_ID_RE = re.compile(r"\{ #([^ }]+)")
HIDDEN_PROTECTION = {"private", "package"}
ANCHOR_RE = re.compile(r"@@anchor:([^@]+)@@")
HEADING_RE = re.compile(r"^#{2,6} ")



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


def apply_scope(text: str) -> str:
    """Nest member lists inside their aggregate and indent them by depth.

    The theme wraps each aggregate's member list in @@ddoc-enter@@ /
    @@ddoc-leave@@ markers. They become <div class="scope" markdown> blocks
    (rendered through md_in_html, styled with a left rule in api.css), and
    headings are shifted one level per nesting depth."""
    for marker in (SCOPE_ENTER, SCOPE_LEAVE, MEMBER_ENTER, MEMBER_LEAVE):
        text = text.replace(marker, f"\n\n{marker}\n\n")
    divs = {
        SCOPE_ENTER: '<div class="scope" markdown="1">',
        MEMBER_ENTER: '<div class="member" markdown="1">',
    }
    out, depth = [], 0
    for line in text.splitlines():
        stripped = line.strip()
        if stripped in divs:
            out.append(divs[stripped])
            if stripped == SCOPE_ENTER:
                depth += 1
        elif stripped in (SCOPE_LEAVE, MEMBER_LEAVE):
            out.append("</div>")
            if stripped == SCOPE_LEAVE:
                depth = max(depth - 1, 0)
        else:
            if line.startswith("## "):
                line = "#" * min(2 + depth, 6) + line[2:]
            out.append(line)
    return "\n".join(out)


def resolve_anchors(text: str) -> str:
    """Use DDoc's declaration anchor for the heading id.

    Overloads share the header anchor name, but dmd emits a unique one in
    DDOC_ANCHOR (name, name.2, name.3, ...) inside each declaration."""
    out: list[str] = []
    pending: int | None = None
    in_fence = False
    for line in text.splitlines():
        if line.startswith("```"):
            in_fence = not in_fence
        match = ANCHOR_RE.search(line)
        if match:
            line = ANCHOR_RE.sub("", line)
            if not in_fence and HEADING_RE.match(line):
                line = line.rstrip() + f" {{ #{match.group(1)} }}"
            elif pending is not None:
                out[pending] = re.sub(r"\{ #[^ }]+", f"{{ #{match.group(1)}", out[pending])
                pending = None
        if not in_fence and HEADING_RE.match(line):
            pending = len(out)
        out.append(line)
    return "\n".join(out)


def non_public_symbols(json_path: Path) -> set[str]:
    """Qualified names of private/package symbols from dmd -X output."""
    hidden: set[str] = set()

    def walk(node: dict, prefix: str) -> None:
        for member in node.get("members", []):
            if member.get("kind") == "import":
                continue
            qualified = f"{prefix}.{member['name']}" if prefix else member["name"]
            if member.get("protection") in HIDDEN_PROTECTION:
                hidden.add(qualified)
            walk(member, qualified)

    for module in json.loads(json_path.read_text()):
        walk(module, "")
    return hidden


def drop_non_public(text: str, hidden: set[str]) -> str:
    """Remove member cards whose symbol is private or package-level."""
    if not hidden:
        return text
    lines = text.splitlines()
    out: list[str] = []
    i = 0
    while i < len(lines):
        if lines[i].strip() == MEMBER_DIV:
            j = i + 1
            while j < len(lines) and not HEADING_RE.match(lines[j]):
                j += 1
            match = ANCHOR_ID_RE.search(lines[j]) if j < len(lines) else None
            anchor = match.group(1) if match else None
            if anchor and (
                anchor in hidden or re.sub(r"\.\d+$", "", anchor) in hidden
            ):
                depth, k = 0, i
                while k < len(lines):
                    stripped = lines[k].strip()
                    if stripped.startswith("<div"):
                        depth += 1
                    elif stripped == "</div>":
                        depth -= 1
                        if depth == 0:
                            break
                    k += 1
                i = k + 1
                continue
        out.append(lines[i])
        i += 1
    return "\n".join(out)


def normalize_blocks(text: str) -> str:
    """Put blank lines around fences and after headings.

    Markdown inside md_in_html containers merges a fence into the following
    paragraph unless blocks are separated, which yields invalid <p><div>."""
    out: list[str] = []
    in_fence = False
    for line in text.splitlines():
        if line.startswith("```"):
            if not in_fence and out and out[-1].strip():
                out.append("")
            out.append(line)
            in_fence = not in_fence
            if not in_fence:
                out.append("")
        else:
            if not in_fence and line.startswith("#"):
                out.append(line)
                out.append("")
            else:
                out.append(line)
    return "\n".join(out)


def tidy(text: str) -> str:
    return re.sub(r"\n{3,}", "\n\n", text).strip() + "\n"


def generate_page(dfile: Path, imports: list[str]) -> tuple[str, Path]:
    fqn = module_name(dfile)
    out = OUT_DIR / f"{fqn}.md"
    symbols = OUT_DIR / f"{fqn}.json"
    subprocess.run(
        [
            "dmd", "-o-", "-D", "-X", f"-Xf{symbols}", f"-Df{out}",
            *imports, str(dfile), str(THEME),
        ],
        cwd=ROOT,
        check=True,
    )
    hidden = non_public_symbols(symbols)
    symbols.unlink()

    text = escape_prose(unescape_fences(out.read_text()))
    text = drop_non_public(apply_scope(resolve_anchors(text)), hidden)
    out.write_text(tidy(normalize_blocks(text)))
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
