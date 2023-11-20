extension Post {

    func prepareForPrompt(_ prompt: BloggingPrompt?) {
        guard let prompt = prompt else {
            return
        }

        content = promptContent(withPromptText: prompt.text)
        bloggingPromptID = String(prompt.promptID)

        if let currentTags = tags {
            tags = "\(currentTags), \(Strings.promptTag)"
        } else {
            tags = Strings.promptTag
        }

        tags?.append(", \(Strings.promptTag)-\(prompt.promptID)")

        // add any additional tags for the prompt.
        if let additionalPostTags = prompt.additionalPostTags, !additionalPostTags.isEmpty {
            additionalPostTags
                .map { ", \($0)" }
                .forEach { self.tags?.append($0) }
        }
    }

    private func promptContent(withPromptText promptText: String) -> String {
        return pullquoteBlock(promptText: promptText) + Strings.emptyParagraphBlock
    }

    private func pullquoteBlock(promptText: String) -> String {
        return """
            <!-- wp:pullquote -->
            <figure class="wp-block-pullquote"><blockquote><p>\(promptText)</p></blockquote></figure>
            <!-- /wp:pullquote -->
            """
    }

    private enum Strings {
        static let promptTag = "dailyprompt"
        static let emptyParagraphBlock = """
        <!-- wp:paragraph -->
        <p></p>
        <!-- /wp:paragraph -->
        """
    }
}
