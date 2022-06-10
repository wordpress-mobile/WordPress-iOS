extension Post {

    func prepareForPrompt(_ prompt: BloggingPrompt?) {
        guard let prompt = prompt else {
            return
        }

        content = prompt.content
        bloggingPromptID = String(prompt.promptID)
    }

}
