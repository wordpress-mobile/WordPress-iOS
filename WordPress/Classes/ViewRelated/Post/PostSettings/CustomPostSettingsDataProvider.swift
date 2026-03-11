import Foundation
import WordPressData

@MainActor
final class CustomPostSettingsDataProvider: PostSettingsDataProvider {
    let blog: Blog
    let editorService: CustomPostEditorService

    // FIXME: meta support missing in AnyPostWithEditContext
    let supportsJetpackMetadata = false
    // FIXME: social sharing support missing in AnyPostWithEditContext
    let isEligibleForSocialSharing = false

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

    var isDeleted: Bool {
        false
    }

    func resolveDisplayedCategories(for settings: PostSettings) -> [String] {
        settings.getCategoryNames(for: blog)
    }

    func customTaxonomies() -> [SiteTaxonomy] {
        editorService.taxonomies
    }

    func resolveTerms(in settings: inout PostSettings) async {
        do {
            let tagsService = AnyTermService(client: editorService.client, endpoint: .tags)
            settings.tags = try await TermResolutionService(taxonomyService: tagsService)
                .resolveNames(for: settings.tags)

            for taxonomy in editorService.taxonomies {
                guard let slugTerms = settings.otherTerms[taxonomy.slug] else { continue }
                let termService = AnyTermService(client: editorService.client, endpoint: taxonomy.endpoint)
                settings.otherTerms[taxonomy.slug] = try await TermResolutionService(taxonomyService: termService)
                    .resolveNames(for: slugTerms)
            }
        } catch {
            // TODO: We need better error handling
            Loggers.app.log(level: .error, "Failed to resolve taxonomy terms: \(error)")
        }
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
