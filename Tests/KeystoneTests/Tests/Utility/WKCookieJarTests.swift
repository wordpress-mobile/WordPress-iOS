import Foundation
import Testing
import WebKit
@testable import WordPress

@MainActor
struct WKCookieJarTests {
    // The cookie store stops storing cookies once its data store is deallocated.
    private let dataStore = WKWebsiteDataStore.nonPersistent()
    private var cookieJar: CookieJar {
        dataStore.httpCookieStore
    }

    init() async {
        await dataStore.httpCookieStore.setWordPressComCookie(username: "testuser")
        await dataStore.httpCookieStore.setWordPressCookie(username: "testuser", domain: "example.com")
    }

    @Test func hasWordPressComAuthCookieForMatchingUser() async {
        let hasCookie = await cookieJar.hasWordPressComAuthCookie(username: "testuser", atomicSite: false)
        #expect(hasCookie)
    }

    @Test func hasNoWordPressComAuthCookieForAnotherUser() async {
        let hasCookie = await cookieJar.hasWordPressComAuthCookie(username: "anotheruser", atomicSite: false)
        #expect(!hasCookie)
    }

    @Test func selfHostedAuthCookieIsScopedToItsSite() async throws {
        let siteURL = try #require(URL(string: "https://example.com/wp-login.php"))
        let anotherSiteURL = try #require(URL(string: "https://example.org/wp-login.php"))

        let hasCookie = await cookieJar.hasWordPressSelfHostedAuthCookie(for: siteURL, username: "testuser")
        let hasCookieForAnotherSite = await cookieJar.hasWordPressSelfHostedAuthCookie(
            for: anotherSiteURL,
            username: "testuser"
        )

        #expect(hasCookie)
        #expect(!hasCookieForAnotherSite)
    }

    @Test func removeWordPressComCookiesKeepsOtherCookies() async {
        await cookieJar.removeWordPressComCookies()

        let cookies = await dataStore.httpCookieStore.allCookies()
        #expect(cookies.map(\.domain) == ["example.com"])
    }

    @Test func removeWordPressComCookiesWaitsForASlowCookieRead() async {
        let removal = Task {
            await cookieJar.removeWordPressComCookies()
        }
        // Lets the removal start its cookie read.
        await Task.yield()
        // WebKit replies on the main thread, so keeping it busy delays the cookie read.
        // The removal has to wait for that read, however long it takes.
        Thread.sleep(forTimeInterval: 2.5)
        await removal.value

        let cookies = await dataStore.httpCookieStore.allCookies()
        #expect(cookies.map(\.domain) == ["example.com"])
    }

    @Test func removeWordPressComCookiesAfterTheDataStoreIsReleased() async {
        // Nothing holds the data store, only its cookie store. The removal still has to finish.
        let cookieJar: CookieJar = WKWebsiteDataStore.nonPersistent().httpCookieStore
        await cookieJar.removeWordPressComCookies()
    }

    @Test func getCookiesFromADataStoreThatHasNotBeenUsedYet() async throws {
        // `allCookies()` can report no cookies for a data store that has not been in touch with
        // WebKit's network process yet, whatever that data store has saved.

        // Always the same identifier, so that a removal that fails leaves one data store behind
        // and not one for every run.
        let identifier = try #require(UUID(uuidString: "0DBBAB0A-FAFA-40CD-A8DF-32A08C939D3D"))
        let cookie = try #require(
            HTTPCookie(properties: [
                .domain: ".wordpress.com",
                .path: "/",
                .name: "saved",
                .value: "value",
                .expires: Date(timeIntervalSinceNow: 3600)
            ])
        )

        weak var dataStoreThatSavedTheCookie: WKWebsiteDataStore?
        do {
            let dataStore = WKWebsiteDataStore(forIdentifier: identifier)
            dataStoreThatSavedTheCookie = dataStore
            await dataStore.httpCookieStore.setCookie(cookie)
            withExtendedLifetime(dataStore) {}
        }
        // WebKit hands out the same object, which has been in touch, for as long as it is alive.
        #expect(dataStoreThatSavedTheCookie == nil)

        do {
            let dataStore = WKWebsiteDataStore(forIdentifier: identifier)
            let cookies = await dataStore.httpCookieStore.getCookies()
            #expect(cookies.map(\.name) == ["saved"])
            withExtendedLifetime(dataStore) {}
        }

        try? await WKWebsiteDataStore.remove(forIdentifier: identifier)
    }
}
