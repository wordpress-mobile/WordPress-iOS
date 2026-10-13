import Foundation
import Testing
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

    private func withCookieStorage(_ body: (HTTPCookieStorage) -> Void) {
        let cookieStorage = HTTPCookieStorage.shared
        removeSandboxCookies(from: cookieStorage)
        defer { removeSandboxCookies(from: cookieStorage) }
        body(cookieStorage)
    }

    private func removeSandboxCookies(from storage: HTTPCookieStorage) {
        StoreSandboxCookie.cookiesToRemove(from: storage.cookies ?? []).forEach(storage.deleteCookie)
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
