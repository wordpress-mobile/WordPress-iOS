import Foundation
import BuildSettingsKit
import WordPressData
import WordPressKit

@MainActor
final class AbstractPostSettingsDataProvider: PostSettingsDataProvider {
    let post: AbstractPost
    let supportsJetpackMetadata = true

    var blog: Blog {
        post.blog
    }

    var capabilities: PostSettingsCapabilities {
        post is Post ? .post() : .page()
    }

    var postContent: String {
        post.content ?? ""
    }

    var navigationTitle: String {
        isPost ? Strings.postSettingsTitle : Strings.pageSettingsTitle
    }

    var isScheduled: Bool {
        post.getOriginal().status == .scheduled
    }

    var isDraftOrPending: Bool {
        post.getOriginal().isStatus(in: [.draft, .pending])
    }

    var isPost: Bool {
        post is Post
    }

    var authorFallbackDisplayName: String {
        post.author?.makePlainText() ?? ""
    }

    var suggestedSlug: String? {
        post.suggested_slug
    }

    var permalinkTemplate: String? {
        post.permalinkTemplateURL
    }

    var lastEditedText: String? {
        guard let date = post.dateModified ?? post.dateCreated else {
            return nil
        }
        return date.toMediumString()
    }

    var postID: Int? {
        guard let postID = post.postID?.intValue, postID > 0 else {
            return nil
        }
        return postID
    }

    var hasRemote: Bool {
        post.hasRemote()
    }

    var isDeleted: Bool {
        guard let context = post.managedObjectContext else {
            return true
        }
        return (try? context.existingObject(with: post.objectID)) == nil
    }

    func resolveDisplayedCategories(for settings: PostSettings) -> [String] {
        settings.getCategoryNames(for: post)
    }

    func customTaxonomies() -> [SiteTaxonomy] {
        let postType: String? = switch post {
        case is Post: "post"
        case is Page: "page"
        default: nil
        }
        guard let postType else {
            return []
        }
        let taxonomies = try? blog.taxonomies
            .filter {
                $0.slug != "post_tag" && $0.slug != "category" && $0.supportedPostTypes.contains(postType)
            }
            .sorted(using: KeyPathComparator(\.name))
        return taxonomies ?? []
    }

    func parentPageText(for pageID: Int?) -> String? {
        guard let page = post as? Page,
              let context = page.managedObjectContext,
              let pageID else {
            return nil
        }
        return Page.parentPageText(in: context, parentID: NSNumber(value: pageID))
    }

    func resolveTerms(in settings: inout PostSettings) async {
        let pendingNames = settings.tags.filter { $0.id == 0 }.map(\.name)
        guard !pendingNames.isEmpty else {
            return
        }

        let service = TagsService(blog: blog)
        let resolved = await service.resolveTerms(named: pendingNames)
        for (name, existing) in resolved {
            if let index = settings.tags.firstIndex(where: { $0.name == name }) {
                settings.tags[index] = PostSettings.Term(id: Int(existing.id), name: existing.name)
            }
        }
    }

    func suggestedTags() async throws -> [String] {
        try await TagSuggestionsService().getSuggestedTags(for: post)
    }

    var isEligibleForSocialSharing: Bool {
        guard let post = post as? Post else {
            return false
        }
        return BuildSettings.current.brand == .jetpack
            && RemoteFeatureFlag.jetpackSocialImprovements.enabled()
            && post.status != .publishPrivate
            && !getPublicizeServices().isEmpty
            && blog.supports(.publicize)
    }

    init(post: AbstractPost) {
        self.post = post
    }

    func makeSettings() -> PostSettings {
        PostSettings(from: post)
    }

    func makeFeaturedImageViewModel() -> PostSettingsFeaturedImageViewModel? {
        PostSettingsFeaturedImageViewModel(post: post)
    }

    func applyLocally(settings: PostSettings) {
        settings.apply(to: post)
    }

    func save(settings: PostSettings) async throws {
        let coordinator = PostCoordinator.shared
        if coordinator.isSyncAllowed(for: post) && post.status == settings.status {
            let revision = post.createRevision()
            settings.apply(to: revision)
            coordinator.setNeedsSync(for: revision)
        } else {
            let changes = settings.makeUpdateParameters(from: post)
            try await coordinator.save(post, changes: changes)
        }
    }

    func publish(settings: PostSettings) async throws {
        let changes = settings.makeUpdateParameters(from: post)
        try await PostCoordinator.shared.publish(post.getOriginal(), parameters: changes)
    }

    // MARK: - Private

    private func getPublicizeServices() -> [PublicizeService] {
        let context = ContextManager.shared.mainContext
        return (try? PublicizeService.allSupportedServices(in: context)) ?? []
    }
}

// MARK: - Localized Strings

private enum Strings {
    static let postSettingsTitle = NSLocalizedString(
        "postSettings.navigationTitle.post",
        value: "Post Settings",
        comment: "The title of the Post Settings screen."
    )

    static let pageSettingsTitle = NSLocalizedString(
        "postSettings.navigationTitle.page",
        value: "Page Settings",
        comment: "The title of the Page Settings screen."
    )
}
