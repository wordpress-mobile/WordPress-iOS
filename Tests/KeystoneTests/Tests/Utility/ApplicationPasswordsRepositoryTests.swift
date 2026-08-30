import Foundation
import Combine
import Testing
import WordPressData
import WordPressAPI
import OHHTTPStubs
import OHHTTPStubsSwift

@testable import WordPress

@Suite(.serialized)
class ApplicationPasswordsRepositoryTests {
    let coreDataStack = ContextManager.forTesting()
    let keychain = TestKeychain()

    /// Stubs registered by this test instance. Other Swift Testing suites run concurrently
    /// and share the process-wide `HTTPStubs` registry, so tests must only remove their own
    /// stubs instead of calling `HTTPStubs.removeAllStubs()`.
    private var stubs: [HTTPStubsDescriptor] = []

    @discardableResult
    private func stub(
        condition: @escaping HTTPStubsTestBlock,
        response: @escaping HTTPStubsResponseBlock
    ) -> HTTPStubsDescriptor {
        let descriptor = OHHTTPStubsSwift.stub(condition: condition, response: response)
        stubs.append(descriptor)
        return descriptor
    }

    private func removeStubs() {
        for descriptor in stubs {
            HTTPStubs.removeStub(descriptor)
        }
        stubs.removeAll()
    }

    func password(of blog: TaggedManagedObjectID<Blog>) async -> String? {
        await coreDataStack.performQuery { [keychain] context in
            try? context.existingObject(with: blog).getApplicationToken(using: keychain)
        }
    }

    @Test
    func simpleSite() async throws {
        defer { removeStubs() }

        try await signInWPComAccount()
        let blog = try await createSimpleSite()

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        await #expect(
            throws: AutoDiscoveryAttemptFailure.self,
            "Simple site does not support application passwords",
            performing: {
                try await repository.createPasswordIfNeeded(for: blog)
            }
        )
    }

    @Test
    func atomicSite() async throws {
        defer { removeStubs() }

        try await signInWPComAccount()
        let blog = try await createAtomicSite()

        stubApiDiscovery(siteHost: "atomic.com")
        stubJetpackProxyCreateApplicationPassword(siteId: 456, password: "abcd efgh")
        stubWPComWpV2GetUser(siteId: 456)

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        try await repository.createPasswordIfNeeded(for: blog)

        let password = await password(of: blog)
        #expect(password == "abcd efgh")
    }

    @Test
    func atomicSiteWithExistingApplicationPassword() async throws {
        defer { removeStubs() }

        try await signInWPComAccount()
        let blog = try await createAtomicSite(existingApplicationPassword: "existing token")

        let validationMonitor = Monitor()
        let creationMonitor = Monitor()
        stubCurrentApplicationPassword(host: "atomic.com", monitor: validationMonitor)
        stubJetpackProxyCreateApplicationPassword(siteId: 456, password: "new token", monitor: creationMonitor)

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        try await repository.createPasswordIfNeeded(for: blog)

        let password = await password(of: blog)
        #expect(password == "existing token")
        #expect(validationMonitor.numberOfRequests > 0)
        #expect(creationMonitor.numberOfRequests == 0)
    }

    @Test
    func staleRestApiRootUrlIsRediscovered() async throws {
        defer { removeStubs() }

        try await signInWPComAccount()
        let blog = try await createAtomicSite(existingApplicationPassword: "existing token")
        // A WP.com proxy API root saved while the site was a Simple site (CMM-2282).
        try await setRestApiRootURL("https://public-api.wordpress.com/wp-json/?rest_route=/sites/atomic.com", of: blog)

        stubWPComProxyRestNoRoute()
        stubApiDiscovery(siteHost: "atomic.com")
        stubJetpackProxyCreateApplicationPassword(siteId: 456, password: "new token")

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        try await repository.createPasswordIfNeeded(for: blog)

        let restApiRootURL = await restApiRootURL(of: blog)
        #expect(restApiRootURL == "https://atomic.com/wp-json/")
    }

    @Test
    func matchingRestApiRootUrlSkipsRediscovery() async throws {
        defer { removeStubs() }

        try await signInWPComAccount()
        let blog = try await createAtomicSite(existingApplicationPassword: "existing token")

        let discoveryMonitor = Monitor()
        stubApiDiscovery(siteHost: "atomic.com", monitor: discoveryMonitor)
        stubCurrentApplicationPassword(host: "atomic.com")
        stubJetpackProxyCreateApplicationPassword(siteId: 456, password: "new token")

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        try await repository.createPasswordIfNeeded(for: blog)

        #expect(discoveryMonitor.numberOfRequests == 0)

        let restApiRootURL = await restApiRootURL(of: blog)
        #expect(restApiRootURL == "https://atomic.com/wp-json")
    }

    @Test
    func staleRestApiRootUrlKeptWhenRediscoveryFails() async throws {
        defer { removeStubs() }

        let staleRootURL = "https://public-api.wordpress.com/wp-json/?rest_route=/sites/atomic.com"

        try await signInWPComAccount()
        let blog = try await createAtomicSite(existingApplicationPassword: "existing token")
        try await setRestApiRootURL(staleRootURL, of: blog)

        stubWPComProxyRestNoRoute()
        stubApiDiscoveryFailure(siteHost: "atomic.com")
        stubJetpackProxyCreateApplicationPassword(siteId: 456, password: "new token")

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        try await repository.createPasswordIfNeeded(for: blog)

        let restApiRootURL = await restApiRootURL(of: blog)
        #expect(restApiRootURL == staleRootURL)
    }

    @Test
    func cancelDuringStaleRestApiRootUrlRediscovery() async throws {
        defer { removeStubs() }

        let staleRootURL = "https://public-api.wordpress.com/wp-json/?rest_route=/sites/atomic.com"

        try await signInWPComAccount()
        let blog = try await createAtomicSite(existingApplicationPassword: "existing token")
        try await setRestApiRootURL(staleRootURL, of: blog)

        // Discovery that can never succeed: a slow homepage and a 404 API root. Without this,
        // discovery may still succeed after cancellation and `WordPressLoginClient.details`
        // itself reports the cancellation, hiding the fallback path under test.
        let discoveryMonitor = Monitor(delay: 0.5)
        stubWPComProxyRestNoRoute()
        stub(condition: isHost("atomic.com") && isPath("/")) { _ in
            discoveryMonitor.requestReceived()

            let response = HTTPStubsResponse(
                data: "<html>homepage</html>".data(using: .utf8)!,
                statusCode: 200,
                headers: ["Link": "<https://atomic.com/wp-json/>; rel=\"https://api.w.org/\""]
            )
            response.responseTime = 0.5
            return response
        }
        stub(condition: isHost("atomic.com") && isPath("/wp-json")) { _ in
            HTTPStubsResponse(data: "<html>page not found</html>".data(using: .utf8)!, statusCode: 404, headers: nil)
        }
        stubJetpackProxyCreateApplicationPassword(siteId: 456, password: "new token")

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        let task = Task {
            try await repository.createPasswordIfNeeded(for: blog)
        }

        await discoveryMonitor.hasReceivedRequest()
        task.cancel()

        let result = await task.result
        #expect(result.isCancellationError())

        let restApiRootURL = await restApiRootURL(of: blog)
        #expect(restApiRootURL == staleRootURL)
    }

    @Test
    func selfHostedSite() async throws {
        defer { removeStubs() }

        let uuid = UUID().uuidString.lowercased()
        let host = "\(uuid).example.com"
        let blog = try await createSelfHostedSite(host: host)

        stubApiDiscovery(siteHost: host)
        stubSelfHostedSiteWpV2GetUser()
        stubSelfHostedSiteCreateApplicationPassword(host: host, password: uuid)

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        try await repository.createPasswordIfNeeded(for: blog)

        let password = await password(of: blog)
        #expect(password == uuid)
    }

    @Test
    func selfHostedSiteWithInaccessibleRestApi() async throws {
        defer { removeStubs() }

        let host = "2.example.com"
        let blog = try await createSelfHostedSite(host: host)

        stubApiDiscovery(siteHost: host)

        stub(condition: isHost(host) && isPath("/wp-login.php")) { _ in
            HTTPStubsResponse(data: "<html>Logged in</html>".data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        stub(
            condition: isHost(host) && isPath("/wp-admin/admin-ajax.php")
                && containsQueryParams(["action": "rest-nonce"])
        ) { _ in
            HTTPStubsResponse(data: "<html>not allowed</html>".data(using: .utf8)!, statusCode: 400, headers: nil)
        }
        stub(condition: isHost(host) && isPath("/wp-admin/post-new.php")) { _ in
            HTTPStubsResponse(data: "<html>not allowed</html>".data(using: .utf8)!, statusCode: 400, headers: nil)
        }
        stub(condition: isHost(host) && isPath("/wp-json/wp/v2/users/me")) { _ in
            let json =
                #"{"code":"rest_not_logged_in","message":"You are not currently logged in.","data":{"status":401}}"#
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 401, headers: nil)
        }

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)

        await #expect(throws: ApplicationPasswordRepositoryError.restApiInaccessible) {
            try await repository.createPasswordIfNeeded(for: blog)
        }
    }

    @Test
    func concurrentCalls() async throws {
        defer { removeStubs() }

        let host = "3.example.com"
        let blog = try await createSelfHostedSite(host: host)

        let monitor = Monitor(delay: 0.1)
        stubApiDiscovery(siteHost: host)
        stubSelfHostedSiteWpV2GetUser()
        stubSelfHostedSiteCreateApplicationPassword(host: host, password: "1234 5678", monitor: monitor)

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)

        await withThrowingTaskGroup(of: Void.self) { group in
            for index in 1...5 {
                group.addTask {
                    try await Task.sleep(for: .milliseconds(10))

                    do {
                        try await repository.createPasswordIfNeeded(for: blog)
                    } catch {
                        Issue.record("Task \(index) receives an unexpected error: \(error)")
                    }
                }
            }
        }

        #expect(monitor.numberOfRequests == 1)

        let password = await password(of: blog)
        #expect(password == "1234 5678")
    }

    @Test
    func cancel() async throws {
        defer { removeStubs() }

        let uuid = UUID().uuidString.lowercased()
        let host = "\(uuid).example.com"
        let blog = try await createSelfHostedSite(host: host)

        let monitor = Monitor(delay: 0.1)
        stubApiDiscovery(siteHost: host)
        stubSelfHostedSiteWpV2GetUser()
        stubSelfHostedSiteCreateApplicationPassword(host: host, password: uuid, monitor: monitor)

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)
        let task = Task {
            try await repository.createPasswordIfNeeded(for: blog)
        }

        try await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let result = await task.result
        #expect(result.isCancellationError())

        let password = await password(of: blog)
        #expect(password == nil)
    }

    @Test
    func cancelFirstCall() async throws {
        defer { removeStubs() }

        let uuid = UUID().uuidString.lowercased()
        let host = "\(uuid).example.com"
        let blog = try await createSelfHostedSite(host: host)

        let monitor = Monitor(delay: 0.5)
        stubApiDiscovery(siteHost: host)
        stubSelfHostedSiteWpV2GetUser()
        stubSelfHostedSiteCreateApplicationPassword(host: host, password: uuid, monitor: monitor)

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)

        let first = Task { try await repository.createPasswordIfNeeded(for: blog) }
        await monitor.hasReceivedRequest()

        let second = Task { try await repository.createPasswordIfNeeded(for: blog) }

        first.cancel()

        let firstResult = await first.result
        let secondResult = await second.result

        #expect(firstResult.isCancellationError())
        #expect(secondResult.isSuccess())

        #expect(monitor.numberOfRequests == 2)

        let password = await password(of: blog)
        #expect(password == uuid)
    }

    @Test(arguments: [1, 2, 3, 4])
    func cancelConcurrentCall(nthTaskToBeCancelled: Int) async throws {
        defer { removeStubs() }

        let uuid = UUID().uuidString.lowercased()
        let host = "\(uuid).example.com"
        let blog = try await createSelfHostedSite(host: host)

        let monitor = Monitor(delay: 0.5)
        stubApiDiscovery(siteHost: host)
        stubSelfHostedSiteWpV2GetUser()
        stubSelfHostedSiteCreateApplicationPassword(host: host, password: uuid, monitor: monitor)

        let repository = ApplicationPasswordRepository.forTesting(coreDataStack: coreDataStack, keychain: keychain)

        let numberOfTasks = 5
        var tasks: [Task<Void, Error>] = []
        // Start a few tasks and ensure they all have started at the end of the for-loop
        for _ in 0..<numberOfTasks {
            let started = CurrentValueSubject<_, Never>(false)
            let task = Task {
                started.value = true
                try await repository.createPasswordIfNeeded(for: blog)
            }
            tasks.append(task)

            _ = await started.values.first(where: { $0 })
            try await Task.sleep(for: .milliseconds(10))
        }

        _ = await monitor.hasReceivedRequest()

        tasks[nthTaskToBeCancelled].cancel()

        for (index, task) in tasks.enumerated() {
            let result = await task.result
            if index == nthTaskToBeCancelled {
                #expect(result.isCancellationError())
            } else {
                #expect(result.isSuccess())
            }
        }

        // If the first call is cancelled, then another password creation attempt should be made by one of the
        // waiting callers. And the rest of the callers should wait on the second attempt.
        if nthTaskToBeCancelled == 0 {
            #expect(monitor.numberOfRequests == 2)
        } else {
            #expect(monitor.numberOfRequests == 1)
        }

        let password = await password(of: blog)
        #expect(password == uuid)
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

    func createAtomicSite(existingApplicationPassword: String? = nil) async throws -> TaggedManagedObjectID<Blog> {
        try await coreDataStack.performAndSave { context in
            let account = try #require(try WPAccount.lookupDefaultWordPressComAccount(in: context))
            let blog = try BlogBuilder(context, dotComID: 456)
                .with(url: "https://atomic.com")
                .withAccount(id: account.objectID)
                .with(atomic: true)
                .build()
            if let existingApplicationPassword {
                blog.username = "demo"
                blog.restApiRootURL = "https://atomic.com/wp-json"
                try blog.setApplicationToken(existingApplicationPassword, using: self.keychain)
            }
            return TaggedManagedObjectID(blog)
        }
    }

    func setRestApiRootURL(_ url: String, of blog: TaggedManagedObjectID<Blog>) async throws {
        try await coreDataStack.performAndSave { context in
            try context.existingObject(with: blog).restApiRootURL = url
        }
    }

    func restApiRootURL(of blog: TaggedManagedObjectID<Blog>) async -> String? {
        await coreDataStack.performQuery { context in
            (try? context.existingObject(with: blog))?.restApiRootURL
        }
    }

    /// WP.com does not serve `?rest_route=/sites/{site}/...` URLs; they all return `rest_no_route`.
    func stubWPComProxyRestNoRoute() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp-json")) { _ in
            let json =
                #"{"code":"rest_no_route","message":"No route was found matching the URL and request method.","data":{"status":404}}"#
            return HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 404, headers: nil)
        }
    }

    func createSelfHostedSite(host: String) async throws -> TaggedManagedObjectID<Blog> {
        try await coreDataStack.performAndSave { context in
            let blog = Blog(context: context)
            blog.url = "https://\(host)"
            blog.xmlrpc = "https://\(host)/xmlrpc.php"
            blog.setValue("admin_url", forOption: "https://\(host)/wp-admin")
            blog.username = "demo"
            blog.password = "pass"
            return TaggedManagedObjectID(blog)
        }
    }

    func stubSelfHostedSiteCreateApplicationPassword(host: String, password: String, monitor: Monitor? = nil) {
        stub(condition: isHost(host) && isPath("/wp-login.php")) { _ in
            HTTPStubsResponse(data: "<html>Logged in</html>".data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        stub(
            condition: isHost(host) && isPath("/wp-admin/admin-ajax.php")
                && containsQueryParams(["action": "rest-nonce"])
        ) { _ in
            HTTPStubsResponse(data: "abcd".data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        stub(condition: isHost(host) && isPath("/wp-json/wp/v2/users/me/application-passwords")) { _ in
            monitor?.requestReceived()

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
            let response = HTTPStubsResponse(data: json.data(using: .utf8)!, statusCode: 200, headers: nil)
            if let delay = monitor?.delay {
                response.responseTime = delay
            }
            return response
        }
    }

    func stubJetpackProxyCreateApplicationPassword(siteId: Int, password: String, monitor: Monitor? = nil) {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/rest/v1.1/jetpack-blogs/\(siteId)/rest-api")) {
            _ in
            monitor?.requestReceived()

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

    func stubCurrentApplicationPassword(host: String, monitor: Monitor? = nil) {
        stub(condition: isHost(host) && isPath("/wp-json/wp/v2/users/me/application-passwords/introspect")) { _ in
            monitor?.requestReceived()

            let json = """
                {
                    "uuid": "56cadaa8-e810-4752-abf9-cc39e120ea97",
                    "app_id": "",
                    "name": "Test",
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

    func stubApiDiscovery(siteHost: String, monitor: Monitor? = nil) {
        stub(condition: isHost(siteHost) && isPath("/")) { _ in
            monitor?.requestReceived()

            return HTTPStubsResponse(
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

private class Monitor {
    let delay: TimeInterval?
    let numberOfRequestsSubject = CurrentValueSubject<_, Never>(0)

    var numberOfRequests: Int {
        numberOfRequestsSubject.value
    }

    private let lock = NSLock()

    init(delay: TimeInterval? = nil) {
        self.delay = delay
    }

    func requestReceived() {
        lock.lock()
        defer { lock.unlock() }

        numberOfRequestsSubject.value += 1
    }

    func hasReceivedRequest() async {
        _ = await numberOfRequestsSubject.values.first(where: { $0 > 0 })
    }
}

@globalActor
private final actor BackgroundActor: GlobalActor {
    static let shared = BackgroundActor()
}

private extension Result {
    func isSuccess() -> Bool {
        if case .success = self {
            return true
        }
        return false
    }
    func isCancellationError() -> Bool {
        if case let .failure(error) = self {
            return error.isCancellationError()
        }
        return false
    }
}
