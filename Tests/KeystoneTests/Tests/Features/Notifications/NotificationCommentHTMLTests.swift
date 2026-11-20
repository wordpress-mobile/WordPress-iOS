import Testing

@testable import WordPress

struct NotificationCommentHTMLTests {

    @Test func wrapsParagraphsAndKeepsEmojiOffsets() {
        let text = "Fast enough 😅\n\nSee you 🙂"
        let ranges = [
            range("p", of: "See you 🙂", in: text, id: "2"),
            range("p", of: "Fast enough 😅", in: text, id: "1")
        ]

        let html = NotificationCommentHTML.html(text: text, ranges: ranges)

        #expect(html == "<p>Fast enough 😅</p>\n\n<p>See you 🙂</p>")
    }

    @Test func nestsRangesByPositionAndParent() {
        let text = "Quoted line\n\nSee the docs and the code."
        let ranges = [
            range("a", of: "docs", in: text, id: "4", parent: "3", url: "https://example.com/docs"),
            range("code", of: "code", in: text, id: "5", parent: "3"),
            range("p", of: "See the docs and the code.", in: text, id: "3"),
            range("p", of: "Quoted line", in: text, id: "2", parent: "1"),
            range("blockquote", of: "Quoted line", in: text, id: "1")
        ]

        let html = NotificationCommentHTML.html(text: text, ranges: ranges)

        #expect(
            html
                == "<blockquote><p>Quoted line</p></blockquote>\n\n"
                + "<p>See the <a href=\"https://example.com/docs\">docs</a> and the <code>code</code>.</p>"
        )
    }

    @Test func turnsNewlinesInPlainTextIntoLineBreaks() {
        let html = NotificationCommentHTML.html(text: "\nFirst line\nSecond line\n", ranges: [])

        #expect(html == "First line<br>Second line")
    }

    @Test func keepsListLayoutWithoutExtraLineBreaks() {
        let text = "\nOne\nTwo\n"
        let ranges: [[String: Any]] = [
            ["type": "ul", "indices": [0, 9], "id": "1"],
            range("li", of: "One", in: text, id: "2", parent: "1"),
            range("li", of: "Two", in: text, id: "3", parent: "1")
        ]

        let html = NotificationCommentHTML.html(text: text, ranges: ranges)

        #expect(html == "<ul><li>One</li>\n<li>Two</li></ul>")
    }

    @Test func escapesTextAndDropsUnsafeMarkup() {
        let text = "<script>alert(1)</script> & click me or him"
        let ranges = [
            range("a", of: "click me", in: text, url: "javascript:alert(1)"),
            range("script", of: "<script>", in: text),
            range("match", of: "him", in: text),
            ["type": "b", "indices": [40, 400]]
        ]

        let html = NotificationCommentHTML.html(text: text, ranges: ranges)

        #expect(html == "&lt;script&gt;alert(1)&lt;/script&gt; &amp; click me or <b>him</b>")
    }

    @Test func escapesLinkURLs() {
        let text = "a link"
        let ranges = [range("a", of: "link", in: text, url: "https://example.com/?a=1&b=\"2\"")]

        let html = NotificationCommentHTML.html(text: text, ranges: ranges)

        #expect(html == "a <a href=\"https://example.com/?a=1&amp;b=&quot;2&quot;\">link</a>")
    }

    // MARK: - Helpers

    /// Builds a range the way the notifications API sends one, with UTF-16 indices of `substring` in `text`.
    private func range(
        _ type: String,
        of substring: String,
        in text: String,
        id: String? = nil,
        parent: String? = nil,
        url: String? = nil
    ) -> [String: Any] {
        let start = text.range(of: substring)!.lowerBound.utf16Offset(in: text)
        var range: [String: Any] = ["type": type, "indices": [start, start + substring.utf16.count]]
        range["id"] = id
        range["parent"] = parent
        range["url"] = url
        return range
    }
}
