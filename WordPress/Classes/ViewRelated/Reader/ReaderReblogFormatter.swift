/// Contains methods to format post reblog content for either Gutenberg (block) editor or Aztec (classic) editor
struct ReaderReblogFormatter {

    static func gutenbergQuote(text: String, citation: String? = nil) -> String {
        let quote = quoteWithCitation(text: text, citation: citation)
        return embedInWpQuote(html: quote)
    }

    static func gutenbergImage(image: String) -> String {
        let imageInHtml = htmlImage(image: image)
        return embedInWpParagraph(html: imageInHtml)
    }


    static func aztecQuote(text: String, citation: String? = nil) -> String {
        let quote = quoteWithCitation(text: text, citation: citation)
        return embedInQuote(html: quote)
    }

    static func aztecImage(image: String) -> String {
        let imageInHtml = htmlImage(image: image)
        return embedInParagraph(html: imageInHtml)
    }
}


// MARK: - Gutenberg formatter helpers
private extension ReaderReblogFormatter {

    static func embedInWpParagraph(html: String) -> String {
        return "<!-- wp:paragraph -->\n<p>\(html)</p>\n<!-- /wp:paragraph -->"
    }

    static func embedInWpQuote(html: String) -> String {
        return "<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\">\(html)</blockquote>\n<!-- /wp:quote -->"
    }
}

// MARK: - Aztec formatter helpers
extension ReaderReblogFormatter {

    static func hyperLink(url: String, text: String) -> String {
        return "<a href=\"\(url)\">\(text)</a>"
    }

    private static func htmlImage(image: String) -> String {
        return "<img src=\"\(image)\">"
    }

    private static func embedInQuote(html: String) -> String {
        return "<blockquote>\(html)</blockquote>"
    }

    private static func embedInParagraph(html: String) -> String {
        return "<p>\(html)</p>"
    }

    private static func embedinCitation(html: String) -> String {
        return "<cite>\(html)</cite>"
    }

    private static func quoteWithCitation(text: String, citation: String? = nil) -> String {
        var formattedText = embedInParagraph(html: text)
        if let citation = citation {
            formattedText.append(embedinCitation(html: citation))
        }
        return formattedText
    }
}
