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
