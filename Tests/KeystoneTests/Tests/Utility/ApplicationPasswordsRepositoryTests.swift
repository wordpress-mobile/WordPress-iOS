import Foundation
import Testing
import WordPressData
import WordPressAPI
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPress

struct ApplicationPasswordsRepositoryTests {
    let coreDataStack = ContextManager.forTesting()
    let keychain = TestKeychain()

    @Test
    func simpleSite() async throws {
        try await signInWPComAccount()
        let blog = try await createSimpleSite()

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        await #expect(throws: AutoDiscoveryAttemptFailure.self, "Simple site does not support application passwords", performing: {
            try await repository.createPasswordIfNeeded(for: blog)
        })
    }

    @Test
    func atomicSite() async throws {
        try await signInWPComAccount()
        let blog = try await createAtomicSite()

        stubApiDiscovery(siteHost: "atomic.com")
        stubJetpackProxyCreateApplicationPassword(siteId: 456, password: "abcd efgh")
        stubWPComWpV2GetUser(siteId: 456)

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        try await repository.createPasswordIfNeeded(for: blog)

        let password = try await coreDataStack.performQuery { context in
            try context.existingObject(with: blog).getApplicationToken(using: keychain)
        }
        #expect(password == "abcd efgh")
    }

    @Test
    func selfHostedSite() async throws {
        let blog = try await createSelfHostedSite()

        stubApiDiscovery(siteHost: "www.example.com")
        stubSelfHostedSiteWpV2GetUser()
        stubSelfHostedSiteCreateApplicationPassword(host: "www.example.com", password: "1234 5678")

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        try await repository.createPasswordIfNeeded(for: blog)

        let password = try await coreDataStack.performQuery { context in
            try context.existingObject(with: blog).getApplicationToken(using: keychain)
        }
        #expect(password == "1234 5678")
    }

    @Test
    func selfHostedSiteWithInaccessibleRestApi() async throws {
        let blog = try await createSelfHostedSite()

        stubApiDiscovery(siteHost: "www.example.com")

        stub(condition: isHost("www.example.com") && isPath("/wp-login.php")) { _ in
            HTTPStubsResponse(data: "<html>Logged in</html>".data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        stub(condition: isHost("www.example.com") && isPath("/wp-admin/admin-ajax.php") && containsQueryParams(["action": "rest-nonce"])) { _ in
            HTTPStubsResponse(data: "<html>not allowed</html>".data(using: .utf8)!, statusCode: 400, headers: nil)
        }
        stub(condition: isHost("www.example.com") && isPath("/wp-admin/post-new.php")) { _ in
            HTTPStubsResponse(data: "<html>not allowed</html>".data(using: .utf8)!, statusCode: 400, headers: nil)
        }
        stub(condition: isHost("www.example.com") && isPath("/wp-json/wp/v2/users/me")) { _ in
            let json = #"{"code":"rest_not_logged_in","message":"You are not currently logged in.","data":{"status":401}}"#
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 401, headers: nil)
        }

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)

        await #expect(throws: ApplicationPasswordRepositoryError.restApiInaccessible) {
            try await repository.createPasswordIfNeeded(for: blog)
        }
    }
}

// MARK: - Helpers

private extension ApplicationPasswordsRepositoryTests {
    func signInWPComAccount() async throws {
        let user = RemoteUser()
        user.userID = 1
        user.username = "testuser"
        user.email = "testuser@example.com"
        let service = AccountService(coreDataStack: coreDataStack)
        service.createOrUpdateAccount(withUsername: "testuser", authToken: "token")
    }

    func createSimpleSite() async throws -> TaggedManagedObjectID<Blog> {
        stubApiDiscoveryFailure(siteHost: "simple.wordpress.com")
        stub(condition: isHost("simple.wordpress.com") && isPath("/wp-json")) { _ in
            HTTPStubsResponse(data: "<html>Page not found</html>".data(using: .utf8)!, statusCode: 404, headers: nil)
        }

        return try await coreDataStack.performAndSave { context in
            let account = try #require(try WPAccount.lookupDefaultWordPressComAccount(in: context))
            let blog = try BlogBuilder(context, dotComID: 123)
                .with(url: "https://simple.wordpress.com")
                .withAccount(id: account.objectID)
                .build()
            return TaggedManagedObjectID(blog)
        }
    }

    func createAtomicSite() async throws -> TaggedManagedObjectID<Blog> {
        try await coreDataStack.performAndSave { context in
            let account = try #require(try WPAccount.lookupDefaultWordPressComAccount(in: context))
            let blog = try BlogBuilder(context, dotComID: 456)
                .with(url: "https://atomic.com")
                .withAccount(id: account.objectID)
                .with(atomic: true)
                .build()
            return TaggedManagedObjectID(blog)
        }
    }

    func createSelfHostedSite() async throws -> TaggedManagedObjectID<Blog> {
        try await coreDataStack.performAndSave { context in
            let blog = BlogBuilder(context, dotComID: nil)
                .with(username: "demo")
                .with(password: "pass")
                .build()
            return TaggedManagedObjectID(blog)
        }
    }

    func stubSelfHostedSiteCreateApplicationPassword(host: String, password: String) {
        stub(condition: isHost(host) && isPath("/wp-login.php")) { _ in
            HTTPStubsResponse(data: "<html>Logged in</html>".data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        stub(condition: isHost(host) && isPath("/wp-admin/admin-ajax.php") && containsQueryParams(["action": "rest-nonce"])) { _ in
            HTTPStubsResponse(data: "abcd".data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        stub(condition: isHost(host) && isPath("/wp-json/wp/v2/users/me/application-passwords")) { _ in
            let json = """
                {
                    "uuid": "56cadaa8-e810-4752-abf9-cc39e120ea97",
                    "app_id": "",
                    "name": "Test",
                    "password": "\(password)",
                    "created": "2025-07-15T22:14:13",
                    "last_used": "2025-07-25T02:43:58",
                    "last_ip": "127.0.0.1",
                    "_links": {
                      "self": [
                        {
                          "href": "https://\(host)/wp-json/wp/v2/users/1/application-passwords/56cadaa8-e810-4752-abf9-cc39e120ea97",
                          "targetHints": {
                            "allow": ["GET", "POST", "PUT", "PATCH", "DELETE"]
                          }
                        }
                      ]
                    }
                }
                """
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: nil)
        }
    }

    func stubJetpackProxyCreateApplicationPassword(siteId: Int, password: String) {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/rest/v1.1/jetpack-blogs/\(siteId)/rest-api")) { _ in
            let json = """
                {
                  "data": {
                    "uuid": "56cadaa8-e810-4752-abf9-cc39e120ea97",
                    "app_id": "",
                    "name": "Test",
                    "password": "\(password)",
                    "created": "2025-07-15T22:14:13",
                    "last_used": "2025-07-25T02:43:58",
                    "last_ip": "127.0.0.1",
                    "_links": {
                      "self": [
                        {
                          "href": "https://atomic/wp-json/wp/v2/users/1/application-passwords/56cadaa8-e810-4752-abf9-cc39e120ea97",
                          "targetHints": {
                            "allow": ["GET", "POST", "PUT", "PATCH", "DELETE"]
                          }
                        }
                      ]
                    }
                  }
                }
                """
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: nil)
        }
    }

    func stubWPComWpV2GetUser(siteId: Int) {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp/v2/sites/\(siteId)/users/me")) { _ in
            let json = """
                {
                  "id": 1,
                  "username": "demo",
                  "name": "demo",
                  "first_name": "",
                  "last_name": "",
                  "email": "tony.li@automattic.com",
                  "url": "https://atomic.com",
                  "description": "",
                  "link": "https://atomic.com/author/demo/",
                  "locale": "en_US",
                  "nickname": "demo",
                  "slug": "demo",
                  "roles": [
                    "administrator"
                  ],
                  "registered_date": "2025-07-11T04:37:16+00:00",
                  "capabilities": {
                    "switch_themes": true,
                    "edit_themes": true,
                    "activate_plugins": true
                  },
                  "extra_capabilities": {
                    "administrator": true
                  },
                  "avatar_urls": {
                    "24": "https://secure.gravatar.com/avatar/hash?s=24&d=mm&r=g",
                    "48": "https://secure.gravatar.com/avatar/hash?s=48&d=mm&r=g",
                    "96": "https://secure.gravatar.com/avatar/hash?s=96&d=mm&r=g"
                  },
                  "meta": {
                    "persisted_preferences": [],
                    "jetpack_donation_warning_dismissed": false
                  },
                  "_links": {
                    "self": [
                      {
                        "href": "https://atomic.com/wp-json/wp/v2/users/1",
                        "targetHints": {
                          "allow": [
                            "GET",
                            "POST",
                            "PUT",
                            "PATCH",
                            "DELETE"
                          ]
                        }
                      }
                    ],
                    "collection": [
                      {
                        "href": "https://atomic.com/wp-json/wp/v2/users"
                      }
                    ]
                  }
                }
                """
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 201, headers: nil)
        }
    }

    func stubSelfHostedSiteWpV2GetUser() {
        stub(condition: isPath("/wp-json/wp/v2/users/me")) { _ in
            let json = """
                {
                  "id": 1,
                  "username": "demo",
                  "name": "demo",
                  "first_name": "",
                  "last_name": "",
                  "email": "tony.li@automattic.com",
                  "url": "https://atomic.com",
                  "description": "",
                  "link": "https://atomic.com/author/demo/",
                  "locale": "en_US",
                  "nickname": "demo",
                  "slug": "demo",
                  "roles": [
                    "administrator"
                  ],
                  "registered_date": "2025-07-11T04:37:16+00:00",
                  "capabilities": {
                    "switch_themes": true,
                    "edit_themes": true,
                    "activate_plugins": true
                  },
                  "extra_capabilities": {
                    "administrator": true
                  },
                  "avatar_urls": {
                    "24": "https://secure.gravatar.com/avatar/hash?s=24&d=mm&r=g",
                    "48": "https://secure.gravatar.com/avatar/hash?s=48&d=mm&r=g",
                    "96": "https://secure.gravatar.com/avatar/hash?s=96&d=mm&r=g"
                  },
                  "meta": {
                    "persisted_preferences": [],
                    "jetpack_donation_warning_dismissed": false
                  },
                  "_links": {
                    "self": [
                      {
                        "href": "https://atomic.com/wp-json/wp/v2/users/1",
                        "targetHints": {
                          "allow": [
                            "GET",
                            "POST",
                            "PUT",
                            "PATCH",
                            "DELETE"
                          ]
                        }
                      }
                    ],
                    "collection": [
                      {
                        "href": "https://atomic.com/wp-json/wp/v2/users"
                      }
                    ]
                  }
                }
                """
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 201, headers: nil)
        }
    }

    func stubApiDiscovery(siteHost: String) {
        stub(condition: isHost(siteHost) && isPath("/")) { _ in
            HTTPStubsResponse(
                data: "<html>homepage</html>".data(using: .utf8)!,
                statusCode: 200,
                headers: ["Link": "<https://\(siteHost)/wp-json/>; rel=\"https://api.w.org/\""]
            )
        }
        stub(condition: isHost(siteHost) && isPath("/wp-json")) { _ in
            let json = """
                {
                  "name": "Site",
                  "description": "",
                  "url": "https://\(siteHost)",
                  "home": "https://\(siteHost)",
                  "gmt_offset": "0",
                  "timezone_string": "",
                  "page_for_posts": 0,
                  "page_on_front": 0,
                  "show_on_front": "posts",
                  "namespaces": [
                    "jetpack/v4",
                    "wpcom/v2",
                    "jetpack/v4/stats-app",
                    "jetpack/v4/import",
                    "wpcom/v3",
                    "jetpack-boost/v1",
                    "my-jetpack/v1",
                    "jetpack/v4/explat",
                    "jetpack/v4/blaze-app",
                    "jetpack/v4/blaze",
                    "wp/v2",
                    "wp-site-health/v1",
                    "wp-block-editor/v1"
                  ],
                  "authentication": {
                    "application-passwords": {
                      "endpoints": {
                        "authorization": "https://\(siteHost)/wp-admin/authorize-application.php"
                      }
                    }
                  },
                  "routes": {
                  },
                  "site_logo": 0,
                  "site_icon": 0,
                  "site_icon_url": "",
                  "_links": {
                    "help": [
                      {
                        "href": "https://developer.wordpress.org/rest-api/"
                      }
                    ]
                  }
                }
                """
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: nil)
        }
    }

    func stubApiDiscoveryFailure(siteHost: String) {
        stub(condition: isHost(siteHost) && isPath("/")) { _ in
            HTTPStubsResponse(data: "<html>homepage</html>".data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        stub(condition: isHost(siteHost) && isPath("/wp-json")) { _ in
            HTTPStubsResponse(data: "<html>page not found</html>".data(using: .utf8)!, statusCode: 404, headers: nil)
        }
    }
}
