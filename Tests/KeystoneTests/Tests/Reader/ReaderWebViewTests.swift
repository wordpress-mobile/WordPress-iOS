import Testing

@testable import WordPress

struct ReaderWebViewTests {
    /// A bare iframe has no wrapper whose end tag would close an unclosed placeholder,
    /// so its own end tag must be renamed or the following content is lost (CMM-2579).
    @Test func placeholderRenamesIframeEndTag() {
        let html = """
            <p>Before</p><iframe src="https://calendar.google.com/calendar/embed" width="800" height="600"></iframe><p>After</p>
            """
        let expected = """
            <p>Before</p><iframe-placeholder src="https://calendar.google.com/calendar/embed" width="800" height="600"></iframe-placeholder><p>After</p>
            """

        #expect(ReaderWebView.addPlaceholder(html) == expected)
    }

    @Test func placeholderRenamesEndTagWithWhitespace() {
        let html = "<video src=\"a\"></video >"
        let expected = "<video-placeholder src=\"a\"></video-placeholder>"

        #expect(ReaderWebView.addPlaceholder(html) == expected)
    }

    /// Both tags of a pair must be renamed whatever their case, or the element never closes.
    @Test func placeholderIgnoresTagCase() {
        let html = "<IFRAME src=\"a\"></iframe><Script></SCRIPT>"
        let expected = "<iframe-placeholder src=\"a\"></iframe-placeholder><script-placeholder></script-placeholder>"

        #expect(ReaderWebView.addPlaceholder(html) == expected)
    }

    @Test func placeholderRenamesVoidElements() {
        let html = "<p><img src=\"a.png\" /><input type=\"text\"></p>"
        let expected = "<p><img-placeholder src=\"a.png\" /><input-placeholder type=\"text\"></p>"

        #expect(ReaderWebView.addPlaceholder(html) == expected)
    }

    @Test func placeholderLeavesOtherTagsAlone() {
        let html = "<figure class=\"wp-block-embed\"><div class=\"wp-block-embed__wrapper\">text</div></figure>"

        #expect(ReaderWebView.addPlaceholder(html) == html)
    }
}
