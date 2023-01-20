extension Post {

    func prepareForPrompt(_ prompt: BloggingPrompt?) {
        guard let prompt = prompt else {
            return
        }

        content = prompt.content
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

    private struct Strings {
        static let promptTag = "dailyprompt"
    }

}
