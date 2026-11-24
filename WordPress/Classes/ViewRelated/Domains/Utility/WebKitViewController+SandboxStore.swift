import UIKit
import WebKit

enum StoreSandboxCookie {
    static let name = "store_sandbox"
    static let domain = ".wordpress.com"

    static func cookie(in storage: HTTPCookieStorage) -> HTTPCookie? {
        storage.cookies?.first(where: { matches($0) && !$0.value.isEmpty })
    }

    static func update(secret: String, in storage: HTTPCookieStorage) {
        let secret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !secret.isEmpty else {
            storage.cookies?.filter(matches).forEach(storage.deleteCookie)
            return
        }

        guard
            let cookie = HTTPCookie(properties: [
                .name: name,
                .value: secret,
                .domain: domain,
                .path: "/"
            ])
        else {
            return
        }

        storage.setCookie(cookie)
    }

    static func cookiesToRemove(from cookies: [HTTPCookie]) -> [HTTPCookie] {
        cookies.filter(matches)
    }

    @MainActor
    static func synchronize(
        from storage: HTTPCookieStorage,
        to cookieStore: WKHTTPCookieStore,
        completion: @escaping () -> Void
    ) {
        if let cookie = cookie(in: storage) {
            cookieStore.setCookie(cookie, completionHandler: completion)
            return
        }

        cookieStore.getAllCookies { cookies in
            let staleCookies = cookiesToRemove(from: cookies)
            guard !staleCookies.isEmpty else {
                completion()
                return
            }

            let group = DispatchGroup()
            staleCookies.forEach { cookie in
                group.enter()
                cookieStore.delete(cookie) {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                completion()
            }
        }
    }

    private static func matches(_ cookie: HTTPCookie) -> Bool {
        cookie.name == name && cookie.domain == domain
    }
}

extension WebKitViewController {
    func configureSandboxStore(_ completion: @escaping () -> Void) {
        // The debug screen keeps the web cookie store in step with the secret, so without a secret
        // there is nothing to do, and presenting checkout doesn't have to wait on WebKit.
        guard let cookie = StoreSandboxCookie.cookie(in: .shared) else {
            completion()
            return
        }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.setCookie(cookie, completionHandler: completion)
    }
}
