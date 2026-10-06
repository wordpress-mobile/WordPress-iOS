#if !UI_TEST_HTTP_FIXTURES
import Testing

/// `HTTPFixtures` and its tests are only compiled when the build sets `UI_TEST_HTTP_FIXTURES`.
/// Without it this is the only test here, and it's reported as skipped so that a run that left the
/// others out says so.
@Test(.disabled("HTTPFixtures is compiled out. Run `swift test -Xswiftc -DUI_TEST_HTTP_FIXTURES` to test it."))
func httpFixtures() {}
#endif
