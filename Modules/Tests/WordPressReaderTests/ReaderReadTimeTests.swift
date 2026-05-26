import Testing
@testable import WordPressReader

struct ReaderReadTimeTests {

    @Test func shortText() {
        #expect(ReaderReadTime.compute("Hello world") == 1)
    }

    @Test func plainText200Words() {
        // 200 words at 200 WPM = exactly 1 minute
        let text = String(repeating: "word ", count: 200)
        #expect(ReaderReadTime.compute(text) == 1)
    }

    @Test func plainText500Words() {
        // 500 words / 200 WPM = 2.5 → rounds up to 3
        let text = String(repeating: "word ", count: 500)
        #expect(ReaderReadTime.compute(text) == 3)
    }

    @Test func plainText1000Words() {
        // 1000 words / 200 WPM = 5 minutes
        let text = String(repeating: "word ", count: 1000)
        #expect(ReaderReadTime.compute(text) == 5)
    }

    @Test func htmlTagsAreStripped() {
        let html = "<p>" + String(repeating: "word ", count: 500) + "</p>"
        let plain = String(repeating: "word ", count: 500)
        #expect(ReaderReadTime.compute(html) == ReaderReadTime.compute(plain))
    }

    @Test func imagesAddPenalty() {
        // 200 words = 60s base. 3 images add 12 + 11 + 10 = 33s → 93s → 2 min
        let base = String(repeating: "word ", count: 200)
        let withImages = base + "<img src=\"a.png\"><img src=\"b.png\"><img src=\"c.png\">"
        #expect(ReaderReadTime.compute(base) == 1)
        #expect(ReaderReadTime.compute(withImages) == 2)
    }

    @Test func codeBlocksAddPenalty() {
        let base = "print 'Hello world'"
        let withCode = "```\(base)```"
        #expect(ReaderReadTime.compute(withCode) >= ReaderReadTime.compute(base))
    }

    @Test func longPost() {
        // ~2500 word blog post with HTML, images, and code
        var post = "<h1>Getting Started with Swift Concurrency</h1>"
        post += "<p>" + String(repeating: "This is a detailed explanation of the concept. ", count: 100) + "</p>"
        post += "<img src=\"diagram1.png\">"
        post +=
            "<p>" + String(repeating: "Here we explore another important aspect of the topic. ", count: 100) + "</p>"
        post += "<img src=\"diagram2.png\">"
        post +=
            "<pre><code>```func fetchData() async throws { let data = try await URLSession.shared.data(from: url)```</code></pre>"
        post += "<p>" + String(repeating: "In conclusion this wraps up the discussion nicely. ", count: 50) + "</p>"
        // ~2500 words / 200 WPM ≈ 12.5 min + image/code penalties → ~13 min
        let result = ReaderReadTime.compute(post)
        #expect(result == 12)
    }

    @Test func cjkTextProducesReasonableEstimate() {
        let text = String(repeating: "测试句子", count: 125) // 500 chars
        #expect(ReaderReadTime.compute(text) > 1)
    }
}
