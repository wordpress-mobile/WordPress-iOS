import Foundation
import WordPressData

@MainActor
final class CustomPostSettingsDataProvider: PostSettingsDataProvider {
    let blog: Blog
    let editorService: CustomPostEditorService

    var capabilities: PostSettingsCapabilities {
        PostSettingsCapabilities(from: editorService.details)
    }

    init(editorService: CustomPostEditorService, blog: Blog) {
        self.editorService = editorService
        self.blog = blog
    }
}
