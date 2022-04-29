
extension Post {

    func prepareForPrompt(_ prompt: Prompt?) {
        guard let prompt = prompt else { return }
        postTitle = prompt.postTitle
        let pullquoteBlock = getPullquoteBlock(title: prompt.promptText,
                                               promptUrl: prompt.promptUrl?.absoluteString,
                                               answerUrl: prompt.answerUrl?.absoluteString,
                                               answerCount: prompt.answerCount)
        content = pullquoteBlock + Strings.emptyParagraph
    }

}

// MARK: - Private methods

private extension Post {

    func getPullquoteBlock(title: String,
                           promptUrl: String?,
                           answerUrl: String?,
                           answerCount: Int) -> String {
        let answerFormat = answerCount == 1 ? Strings.answerInfoSingularFormat : Strings.answerInfoPluralFormat
        let answerText = String(format: answerFormat, answerCount)
        let promptUrlHtml = getUrlHtml(url: promptUrl, urlText: Strings.prompt)
        let answerUrlHtml = getUrlHtml(url: answerUrl, urlText: answerText)
        let separatorText = promptUrlHtml.isEmpty || answerUrlHtml.isEmpty ? "" : " — "
        let subtitleHtml = promptUrlHtml.isEmpty && answerUrlHtml.isEmpty ? "" :  "<cite>\(promptUrlHtml)\(separatorText)\(answerUrlHtml)</cite>"
        return """
            <!-- wp:pullquote -->
            <figure class="wp-block-pullquote"><blockquote><p>\(title)</p>\(subtitleHtml)</blockquote></figure>
            <!-- /wp:pullquote -->
            """
    }

    func getUrlHtml(url: String?, urlText: String) -> String {
        guard let url = url else { return "" }
        return "<a href=\"\(url)\">\(urlText)</a>"
    }

    // MARK: - Strings

    struct Strings {
        static let prompt = NSLocalizedString("Prompt", comment: "Prompt link text in a new blogging prompts post")
        static let answerInfoSingularFormat = NSLocalizedString("%1$d answer", comment: "Singular format string for displaying the number of users that answered the blogging prompt.")
        static let answerInfoPluralFormat = NSLocalizedString("%1$d answers", comment: "Plural format string for displaying the number of users that answered the blogging prompt.")
        static let emptyParagraph = """
            <!-- wp:paragraph -->
            <p></p>
            <!-- /wp:paragraph -->
            """
    }

}

// MARK: - Temporary prompt object

// TODO: Remove after prompt object is created and use that
struct Prompt {
    let postTitle: String
    let promptText: String
    let promptUrl: URL?
    let answerUrl: URL?
    let answerCount: Int

    static let examplePrompt = Prompt(postTitle: "Cast the movie of my life",
                                      promptText: "Cast the movie of your life.",
                                      promptUrl: URL(string: "https://wordpress.com"),
                                      answerUrl: URL(string: "https://wordpress.com"),
                                      answerCount: 19)
}
