import Foundation
import JetpackSocial
import WebKit
import WordPressData

/// Adapts the app's `Blog`-backed `RequestAuthenticator` to the
/// module-facing `SocialOAuthAuthenticator` protocol.
///
/// Keeps every reference to `Blog`, `WPAccount`, and `CookieJar` inside
/// the app target so the JetpackSocial module stays free of Core Data.
/// `WKHTTPCookieStore` already conforms to `CookieJar` via the extension
/// in `WordPress/Classes/Utility/WebViewController/CookieJar.swift`, so
/// we can hand it to `RequestAuthenticator.request` as-is.
struct BlogSocialOAuthAuthenticator: SocialOAuthAuthenticator {
    private let blogID: TaggedManagedObjectID<Blog>
    private let coreDataStack: CoreDataStack

    init(blog: Blog, coreDataStack: CoreDataStack = ContextManager.shared) {
        self.blogID = TaggedManagedObjectID(blog)
        self.coreDataStack = coreDataStack
    }

    func authenticatedRequest(
        for url: URL,
        into cookieStore: WKHTTPCookieStore
    ) async -> URLRequest {
        let authenticator: RequestAuthenticator?
        do {
            authenticator = try await coreDataStack.performQuery { [blogID] context in
                let blog = try context.existingObject(with: blogID)
                return RequestAuthenticator(blog: blog)
            }
        } catch {
            Loggers.app.error("BlogSocialOAuthAuthenticator failed to resolve blog: \(error)")
            return URLRequest(url: url)
        }
        guard let authenticator else {
            Loggers.app.error(
                "BlogSocialOAuthAuthenticator: RequestAuthenticator(blog:) returned nil — using unauthenticated request"
            )
            return URLRequest(url: url)
        }
        return await withCheckedContinuation { continuation in
            // `WKHTTPCookieStore` mutation requires the main thread, and
            // `RequestAuthenticator.request` seeds cookies synchronously
            // into the jar before invoking the completion.
            DispatchQueue.main.async {
                authenticator.request(url: url, cookieJar: cookieStore) { request in
                    continuation.resume(returning: request)
                }
            }
        }
    }
}
