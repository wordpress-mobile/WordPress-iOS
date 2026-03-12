import Foundation
import WordPressKit
import WordPressCore
import WordPressData
import WordPressAPI
import WordPressAPIInternal

@objc public class BlogServiceRemoteCoreREST: NSObject, BlogServiceRemote {
    let client: WordPressClient

    @objc public convenience init?(blog: Blog) {
        guard let site = try? WordPressSite(blog: blog) else { return nil }

        self.init(
            client: WordPressClientFactory.shared.instance(for: site)
        )
    }

    init(client: WordPressClient) {
        self.client = client
    }

    public func getAllAuthors(success: UsersHandler?, failure: (((any Error)?) -> Void)?) {
        Task { @MainActor in
            do {
                let sequence = await client.api.users.sequenceWithEditContext(
                    params: UserListParams(perPage: 100)
                )
                let users: [RemoteUser] = try await sequence.reduce(into: []) {
                    let page = $1.map(RemoteUser.init(user:))
                    $0.append(contentsOf: page)
                }
                success?(users)
            } catch {
                failure?(error)
            }
        }
    }

    public func syncPostTypes(success: PostTypesHandler?, failure: (((any Error)?) -> Void)?) {
        Task { @MainActor in
            do {
                let response = try await client.api.postTypes.listWithEditContext()
                let postTypes = response.data.postTypes.map { _, details in
                    let postType = RemotePostType()
                    postType.name = details.slug
                    postType.label = details.name
                    postType.apiQueryable = NSNumber(value: details.viewable)
                    return postType
                }
                success?(postTypes)
            } catch {
                failure?(error)
            }
        }
    }

    public func syncPostFormats(success: PostFormatsHandler?, failure: (((any Error)?) -> Void)?) {
        Task { @MainActor in
            let activeTheme: ThemeWithViewContext?
            do {
                let response = try await client.api.themes.listWithViewContext(
                    params: ThemeListParams(status: .active)
                )
                activeTheme = response.data.first
            } catch {
                failure?(error)
                return
            }

            guard let activeTheme else {
                failure?(ActiveThemeNotFoundError())
                return
            }

//            taxonomy-post_format-post-format-[id]
//            │        │           │
//            │        │           └─ term slug: "post-format-aside"
//            │        │              (WP prefixes format terms with "post-format-")
//            │        │
//            │        └─ taxonomy name: "post_format"
//            │
//            └─ template type: taxonomy archive
            let slugPrefix = "taxonomy-post_format-post-format-"

            var labelsBySlugs: [String: String] = [:]
            if let templateTypes = activeTheme.defaultTemplateTypes {
                for templateType in templateTypes where templateType.slug.hasPrefix(slugPrefix) {
                    let formatSlug = String(templateType.slug.dropFirst(slugPrefix.count))
                    // This title value is different from XMLRPC: "Post Format: Standard" instead of just "Standard".
                    // Considering the title value is localized, I don't think we can extract the "Standard" part out.
                    labelsBySlugs[formatSlug] = templateType.title
                }
            }

            var formats: [String: String] = [:]
            if let data = activeTheme.themeSupports?[.formats], case let .vecString(slugs) = data {
                for slug in slugs {
                    formats[slug] = labelsBySlugs[slug] ?? slug.capitalized
                }
            }
            success?(formats)
        }
    }

    static func mapSiteSettings(_ siteSettings: SiteSettingsWithEditContext) -> RemoteBlogSettings {
        let settings = RemoteBlogSettings()

        // General
        settings.name = siteSettings.title
        settings.tagline = siteSettings.description
        settings.timezoneString = siteSettings.timezone

        // Writing
        let format = siteSettings.defaultPostFormat
        if format.isEmpty || format == "0" {
            settings.defaultPostFormat = "standard"
        } else {
            settings.defaultPostFormat = format
        }
        settings.defaultCategoryID = NSNumber(value: siteSettings.defaultCategory)
        settings.dateFormat = siteSettings.dateFormat
        settings.timeFormat = siteSettings.timeFormat
        settings.startOfWeek = String(siteSettings.startOfWeek)
        settings.postsPerPage = NSNumber(value: siteSettings.postsPerPage)

        // The following properties are not available from the Core REST API
        // site settings endpoint.
        settings.privacy = nil
        settings.languageID = nil
        settings.iconMediaID = nil
        settings.gmtOffset = nil
        settings.commentsAllowed = nil
        settings.commentsBlocklistKeys = nil
        settings.commentsCloseAutomatically = nil
        settings.commentsCloseAutomaticallyAfterDays = nil
        settings.commentsFromKnownUsersAllowlisted = nil
        settings.commentsMaximumLinks = nil
        settings.commentsModerationKeys = nil
        settings.commentsPagingEnabled = nil
        settings.commentsPageSize = nil
        settings.commentsRequireManualModeration = nil
        settings.commentsRequireNameAndEmail = nil
        settings.commentsRequireRegistration = nil
        settings.commentsSortOrder = nil
        settings.commentsThreadingEnabled = nil
        settings.commentsThreadingDepth = nil
        settings.pingbackInboundEnabled = nil
        settings.pingbackOutboundEnabled = nil
        settings.relatedPostsAllowed = nil
        settings.relatedPostsEnabled = nil
        settings.relatedPostsShowHeadline = nil
        settings.relatedPostsShowThumbnails = nil
        settings.ampSupported = nil
        settings.ampEnabled = nil
        settings.sharingButtonStyle = nil
        settings.sharingLabel = nil
        settings.sharingTwitterName = nil
        settings.sharingCommentLikesEnabled = nil
        settings.sharingDisabledLikes = nil
        settings.sharingDisabledReblogs = nil

        return settings
    }

    @objc public func syncBlogSettings(
        success: SettingsHandler?,
        failure: (((any Error)?) -> Void)?
    ) {
        Task { @MainActor in
            do {
                let response = try await client.api.siteSettings
                    .retrieveWithEditContext()
                let settings = Self.mapSiteSettings(response.data)
                success?(settings)
            } catch {
                failure?(error)
            }
        }
    }
}

struct ActiveThemeNotFoundError: LocalizedError {
    var errorDescription: String? {
        NSLocalizedString(
            "blogDetails.activeThemeNotFound.errorDescription",
            value: "The active theme could not be found for this site.",
            comment: "Error message shown when the active theme cannot be found for a site."
        )
    }
}

private extension RemoteUser {
    convenience init(user: UserWithEditContext) {
        self.init()
        self.userID = NSNumber(value: user.id)
        self.username = user.username
        self.email = user.email
        self.displayName = user.name
        self.avatarURL = user.avatarUrls?.avatarURL()?.absoluteString
    }
}
