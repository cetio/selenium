# 05 — Migration Strategy

## Phase 1: Foundation (No Breaking Changes to Existing API)

Create new directory structure and modules alongside the existing files.

1. Create `source/selenium/errors.d` — extract exception types from `api.d`.
2. Create `source/selenium/types.d` — extract all enums and structs from `api.d`.
3. Create `source/selenium/locator.d` — extract `ElementLocator` and factories from `api.d`.
4. Create `source/selenium/protocol/client.d` — write new `Client` class.
5. Create `source/selenium/protocol/response.d` — write response parsing / error mapping.
6. Rewrite `source/selenium/driver.d` — new `Driver` class with merged session, comptime locators, and zero-config auto-detection (`Driver.start()`).
7. Create `source/selenium/element.d` — new `Element` class with search context.
8. Create `source/selenium/page.d` — simple `Page` base class.
9. Create `source/selenium/package.d` and `source/selenium/protocol/package.d`.

At the end of this phase, the old files (`api.d`, `session.d`, `workflow.d`) still compile and are still imported by `tests/`. The new modules are available for testing.

## Phase 2: Test Migration

1. Rewrite `source/tests/behaviors.d` to test new `types.d` and `locator.d` directly.
2. Rewrite `source/tests/dynamic.d` to use the new `Driver` API:
   ```d
   // Zero-config start (auto-detects Chrome, finds chromedriver, launches, creates session)
   Driver driver = Driver.start();
   scope(exit) driver.quit();
   driver.url("http://example.com");
   Element heading = driver.findOne!"tag"("h1");
   assert(heading.text == "Example Domain");
   ```
3. Verify `findOne` and `findMany` with both comptime strategies and runtime `ElementLocator`.

## Phase 3: Deprecate Old Modules

1. Mark `source/selenium/api.d` with `deprecated` module attribute.
2. Mark `source/selenium/session.d` with `deprecated` module attribute.
3. Mark `source/selenium/workflow.d` with `deprecated` module attribute.
4. Keep `source/selenium/driver.d` — it has been rewritten in-place.
5. Update any internal imports to use new modules.

## Phase 4: Remove Old Modules

1. Delete `source/selenium/api.d`.
2. Delete `source/selenium/session.d`.
3. Delete `source/selenium/workflow.d`.
4. Verify no references to old names remain in the codebase:
   - `SeleniumSession`, `SeleniumApi`, `SeleniumApiConnection`, `SeleniumApiConnector`
   - `SeleniumWindow`, `SeleniumNavigation`, `SeleniumCookie`
   - `SeleniumPage`, `SeleniumDriver`
   - `SeleniumException`
5. Update `README.md` with new API examples.

## Phase 5: Protocol Modernization

1. Update `selenium/protocol/response.d` to fully parse W3C WebDriver responses:
   - Extract `value` directly
   - Check `error` field for failure
   - Ignore `status` integer (legacy)
2. Update `WebElement` struct to abstract both legacy `ELEMENT` and W3C `element-6066-11e4-a52e-4f735466cecf` keys:
   ```d
   struct WebElement
   {
       string id;

       static WebElement fromResponse(JSONValue response)
       {
           WebElement ret;
           if (auto p = "element-6066-11e4-a52e-4f735466cecf" in response)
               ret.id = p.str;
           else if (auto p = "ELEMENT" in response)
               ret.id = p.str;
           return ret;
       }
   }
   ```
3. Update `Capabilities` serialization for W3C format:
   ```d
   JSONValue toJSONValue() const
   {
       JSONValue ret = JSONValue.emptyObject;
       ret["capabilities"] = JSONValue.emptyObject;
       ret["capabilities"]["alwaysMatch"] = buildLegacyCapabilities();
       return ret;
   }
   ```
4. Remove deprecated endpoints from `Client`:
   - `/touch/*`
   - `/local_storage`
   - `/session_storage`
   - `/ime/*`
   - `/application_cache`
   - `/orientation`
   - `/location`
5. Update endpoint paths to W3C equivalents:
   - `/window_handle` -> `/window`
   - `/window_handles` -> `/window/handles`
   - `/window/size` -> `/window/rect`
   - `/timeouts/implicit_wait` -> `/timeouts`


