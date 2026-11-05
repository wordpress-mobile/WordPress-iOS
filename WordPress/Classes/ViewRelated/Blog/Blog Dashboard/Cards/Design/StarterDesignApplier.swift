import Foundation
import Logging
import WordPressData
import WordPressKit
import WordPressShared

/// Applies a starter design to an existing site.
///
/// The theme is the design, so activating the theme is the whole success condition. Theme setup, which asks
/// WordPress.com to insert placeholder posts, runs afterwards on a best-effort basis like it does on the web: its
/// outcome is logged and never changes the result.
@MainActor
final class StarterDesignApplier {
    enum ApplyError: Error {
        case missingSiteID
        case missingTheme
    }

    private static let logger = Logger(label: "org.wordpress.dashboard.design-card")

    private let blog: Blog
    private let api: WordPressComRestApi
    private let record: BlankSiteRecord

    init(blog: Blog, api: WordPressComRestApi, record: BlankSiteRecord = BlankSiteRecord()) {
        self.blog = blog
        self.api = api
        self.record = record
    }

    /// - Returns: The theme setup started after a successful activation, or `nil` when the site is not a Simple site.
    ///   Callers need not wait for it: it can take many seconds and its outcome does not change the result.
    /// - Throws: The theme activation error. The site is unchanged and the blank site record is untouched.
    @discardableResult
    func apply(_ design: RemoteSiteDesign) async throws -> Task<Void, Never>? {
        guard let siteID = blog.dotComID?.intValue else {
            throw ApplyError.missingSiteID
        }
        guard let themeID = design.themeSlug else {
            throw ApplyError.missingTheme
        }

        try await activateTheme(themeID, siteID: siteID)

        record.remove(siteID: siteID)
        WPAnalytics.track(.designCardDesignApplied, properties: ["design": design.slug], blog: blog)

        // Theme setup only exists on Simple sites, as on the web.
        guard blog.isHostedAtWPcom, !blog.isAtomic else {
            return nil
        }
        return Task {
            await runThemeSetup(siteID: siteID)
        }
    }

    private func activateTheme(_ themeID: String, siteID: Int) async throws {
        let remote = ThemeServiceRemote(wordPressComRestApi: api)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            _ = remote.activateThemeId(
                themeID,
                forBlogId: NSNumber(value: siteID),
                success: { _ in continuation.resume() },
                failure: { error in continuation.resume(throwing: error ?? URLError(.unknown)) }
            )
        }
    }

    private func runThemeSetup(siteID: Int) async {
        do {
            let isCompleted = try await StarterDesignServiceRemote(wordPressComRestApi: api)
                .runThemeSetup(siteID: siteID)
            if isCompleted {
                Self.logger.info("Theme setup completed for site \(siteID)")
            } else {
                Self.logger.error("Theme setup did not complete for site \(siteID)")
            }
        } catch {
            Self.logger.error("Theme setup failed for site \(siteID): \(error)")
        }
    }
}
