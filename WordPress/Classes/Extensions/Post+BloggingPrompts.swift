extension Post {

    func prepareForPrompt(_ prompt: BloggingPrompt?) {
        guard let prompt = prompt else {
            return
        }

        content = promptContentWithEmptyParagraph(promptText: prompt.text)
        bloggingPromptID = String(prompt.promptID)

        if let currentTags = tags {
            tags = "\(currentTags), \(Strings.promptTag)"
        } else {
            tags = Strings.promptTag
        }

        if FeatureFlag.bloggingPromptsEnhancements.enabled {
            tags?.append(", \(Strings.promptTag)-\(prompt.promptID)")
        }
    }

    private func promptContentWithEmptyParagraph(promptText: String) -> String {
        pullquoteBlock(promptText: promptText) + Strings.emptyParagraphBlock
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
