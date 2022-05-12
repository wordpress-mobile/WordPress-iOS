extension Post {

    func prepareForPrompt(_ prompt: BloggingPrompt?) {
        guard let prompt = prompt else {
            return
        }
        postTitle = prompt.title
        content = prompt.content
    }

}
