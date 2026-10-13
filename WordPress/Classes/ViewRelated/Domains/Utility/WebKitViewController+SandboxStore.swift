import UIKit
import WebKit

enum StoreSandboxCookie {
    static let name = "store_sandbox"
    static let domain = ".wordpress.com"

    static func cookie(in storage: HTTPCookieStorage) -> HTTPCookie? {
        storage.cookies?.first(where: { matches($0) && !$0.value.isEmpty })
    }

    static func update(secret: String, in storage: HTTPCookieStorage) {
        guard !secret.isEmpty else {
            storage.cookies?.filter(matches).forEach(storage.deleteCookie)
            return
        }

        guard let cookie = HTTPCookie(properties: [
            .name: name,
            .value: secret,
            .domain: domain,
            .path: "/"
        ]) else {
            return
        }

        storage.setCookie(cookie)
    }

    static func cookiesToRemove(from cookies: [HTTPCookie]) -> [HTTPCookie] {
        cookies.filter(matches)
    }

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
            if let cookie = cookie(in: storage) {
                cookieStore.setCookie(cookie, completionHandler: completion)
                return
            }

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
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        StoreSandboxCookie.synchronize(from: .shared, to: cookieStore, completion: completion)
    }
}
