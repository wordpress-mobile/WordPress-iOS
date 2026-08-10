import Foundation
import Testing
import WordPressShared

struct URLWordPressComHostTests {

    @Test func allowsWordPressComHosts() {
        #expect(URL(string: "https://wordpress.com/img.png")!.isWordPressComHost)
        #expect(URL(string: "https://example.wordpress.com/img.png")!.isWordPressComHost)
        #expect(URL(string: "https://example.files.wordpress.com/img.png")!.isWordPressComHost)
        #expect(URL(string: "https://public-api.wordpress.com/file")!.isWordPressComHost)
        #expect(URL(string: "https://i0.wp.com/example.com/img.png")!.isWordPressComHost)
        #expect(URL(string: "https://wp.com/img.png")!.isWordPressComHost)
    }

    @Test func matchesHostCaseInsensitively() {
        #expect(URL(string: "https://example.files.WORDPRESS.COM/img.png")!.isWordPressComHost)
        #expect(URL(string: "https://I0.WP.COM/img.png")!.isWordPressComHost)
    }

    @Test func rejectsUnrelatedHosts() {
        #expect(!URL(string: "https://attacker.example.com/img.png")!.isWordPressComHost)
    }

    @Test func rejectsSubstringLookalikeHosts() {
        // `contains`-style checks would wrongly accept all of these.
        #expect(!URL(string: "https://evilwordpress.com/img.png")!.isWordPressComHost)
        #expect(!URL(string: "https://evilwp.com/img.png")!.isWordPressComHost)
        #expect(!URL(string: "https://myevilwp.com/img.png")!.isWordPressComHost)
        #expect(!URL(string: "https://wordpress.com.attacker.example/img.png")!.isWordPressComHost)
        #expect(!URL(string: "https://wp.com.attacker.example/img.png")!.isWordPressComHost)
    }

    @Test func rejectsUserinfoSpoofedHost() {
        // The real destination host is `attacker.example`, not `wordpress.com`.
        #expect(!URL(string: "https://wordpress.com@attacker.example/img.png")!.isWordPressComHost)
    }

    @Test func rejectsHostlessURLs() {
        #expect(!URL(string: "file:///var/img.png")!.isWordPressComHost)
    }
}
