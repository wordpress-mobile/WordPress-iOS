import Foundation
import Testing
import WebKit
@testable import WordPress

@Suite(.serialized)
struct StoreSandboxCookieTests {
    @Test
    func cookiesToRemoveIncludesStaleSandboxCookie() {
        let staleCookie = sandboxCookie(value: "secret")

        let cookiesToRemove = StoreSandboxCookie.cookiesToRemove(from: [staleCookie])

        #expect(cookiesToRemove.count == 1)
        #expect(cookiesToRemove.first?.value == staleCookie.value)
    }

    @Test
    func emptySecretRemovesPreviouslyStoredCookie() {
        withCookieStorage { cookieStorage in
            let cookie = sandboxCookie(value: "secret")
            cookieStorage.setCookie(cookie)
            #expect(
                StoreSandboxCookie.cookiesToRemove(from: cookieStorage.cookies ?? [])
                    .contains(where: { $0.value == cookie.value })
            )

            StoreSandboxCookie.update(secret: "", in: cookieStorage)

            #expect(StoreSandboxCookie.cookiesToRemove(from: cookieStorage.cookies ?? []).isEmpty)
        }
    }

    @Test
    func nonemptySecretStoresCookieForInjection() {
        withCookieStorage { cookieStorage in
            StoreSandboxCookie.update(secret: "secret", in: cookieStorage)

            #expect(StoreSandboxCookie.cookie(in: cookieStorage)?.value == "secret")
        }
    }

    @Test
    func cookieWithEmptySecretIsNotReturnedForInjection() {
        withCookieStorage { cookieStorage in
            cookieStorage.setCookie(sandboxCookie(value: ""))

            #expect(StoreSandboxCookie.cookie(in: cookieStorage) == nil)
        }
    }

    @Test
    func whitespaceOnlySecretRemovesPreviouslyStoredCookie() {
        withCookieStorage { cookieStorage in
            cookieStorage.setCookie(sandboxCookie(value: "secret"))

            StoreSandboxCookie.update(secret: " \n\t", in: cookieStorage)

            #expect(StoreSandboxCookie.cookiesToRemove(from: cookieStorage.cookies ?? []).isEmpty)
        }
    }

    @Test @MainActor
    func synchronizeRemovesStaleCookieFromWebCookieStore() async {
        let dataStore = WKWebsiteDataStore.nonPersistent()
        let loggedInCookie = HTTPCookie(properties: [
            .name: "wordpress_logged_in",
            .value: "user",
            .domain: StoreSandboxCookie.domain,
            .path: "/"
        ])!
        await dataStore.httpCookieStore.setCookie(sandboxCookie(value: "secret"))
        await dataStore.httpCookieStore.setCookie(loggedInCookie)

        await withCheckedContinuation { continuation in
            StoreSandboxCookie.synchronize(from: MockCookieJar(), to: dataStore.httpCookieStore) {
                continuation.resume()
            }
        }

        let remainingCookies = await dataStore.httpCookieStore.allCookies()
        #expect(remainingCookies.map(\.name) == ["wordpress_logged_in"])
    }

    private func withCookieStorage(_ body: (HTTPCookieStorage) -> Void) {
        body(MockCookieJar())
    }

    private func sandboxCookie(value: String) -> HTTPCookie {
        HTTPCookie(properties: [
            .name: StoreSandboxCookie.name,
            .value: value,
            .domain: StoreSandboxCookie.domain,
            .path: "/"
        ])!
    }
}
