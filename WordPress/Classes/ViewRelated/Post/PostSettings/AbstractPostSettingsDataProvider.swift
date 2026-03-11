import Foundation
import WordPressData

@MainActor
final class AbstractPostSettingsDataProvider: PostSettingsDataProvider {
    let post: AbstractPost

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

    init(post: AbstractPost) {
        self.post = post
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
