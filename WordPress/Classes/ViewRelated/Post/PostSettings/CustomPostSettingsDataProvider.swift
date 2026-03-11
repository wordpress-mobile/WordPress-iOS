import Foundation
import WordPressData

@MainActor
final class CustomPostSettingsDataProvider: PostSettingsDataProvider {
    let blog: Blog
    let editorService: CustomPostEditorService

    var capabilities: PostSettingsCapabilities {
        PostSettingsCapabilities(from: editorService.details)
    }

    var postContent: String {
        editorService.post?.content.raw ?? ""
    }

    var navigationTitle: String {
        String.localizedStringWithFormat(
            Strings.customPostSettingsTitle,
            editorService.details.name
        )
    }

    var isScheduled: Bool {
        editorService.post?.status == .future
    }

    var isDraftOrPending: Bool {
        if let post = editorService.post {
            return post.status == .draft || post.status == .pending
        }
        return true
    }

    var isPost: Bool {
        editorService.details.slug == "post"
    }

    var authorFallbackDisplayName: String {
        ""
    }

    var suggestedSlug: String? {
        editorService.post?.generatedSlug
    }

    var permalinkTemplate: String? {
        editorService.post?.permalinkTemplate
    }

    var lastEditedText: String? {
        editorService.post?.modifiedGmt.toMediumString()
    }

    var postID: Int? {
        guard let id = editorService.post?.id else { return nil }
        return id > 0 ? Int(id) : nil
    }

    var hasRemote: Bool {
        editorService.post != nil
    }

    init(editorService: CustomPostEditorService, blog: Blog) {
        self.editorService = editorService
        self.blog = blog
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let customPostSettingsTitle = NSLocalizedString(
        "postSettings.navigationTitle.customPostType",
        value: "%1$@ Settings",
        comment: "The title of the Post Settings screen for custom post types. %1$@ is the post type name."
    )
}
