import Testing
import WordPressShared

struct BoolStringRepresentationTests {
    @Test func stringLiteralReflectsBooleanValue() {
        #expect(true.stringLiteral == "true")
        #expect(false.stringLiteral == "false")
    }
}
