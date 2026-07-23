import Foundation
import WordPressData

extension BloggingPrompt {
    var editorContent: String {
        """
        <!-- wp:pullquote -->
        <figure class="wp-block-pullquote"><blockquote><p>\(text)</p></blockquote></figure>
        <!-- /wp:pullquote -->
        <!-- wp:paragraph -->
        <p></p>
        <!-- /wp:paragraph -->
        """
    }

    var editorTags: [String] {
        [Post.Strings.promptTag, "\(Post.Strings.promptTag)-\(promptID)"] + (additionalPostTags ?? [])
    }
}

extension Post {
    func prepareForPrompt(_ prompt: BloggingPrompt?) {
        guard let prompt else { return }
        content = prompt.editorContent
        bloggingPromptID = String(prompt.promptID)
        tags = (AbstractPost.makeTags(from: tags ?? "") + prompt.editorTags)
            .joined(separator: ", ")
    }

    enum Strings {
        static let promptTag = "dailyprompt"
    }
}
