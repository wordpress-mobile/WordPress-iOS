import Foundation
import WordPressData
import WordPressShared
import WordPressKit
import WordPressAPI
import WordPressCore

/// Application passwords are stored on the WordPress site. We _can_ create as many application passwords as we want, which
/// should have no major impact on the users or the site itself. We should avoid that, though, because users can
/// see all of their application passwords in their profile, and it may give a messy impression if the app creates multiple
/// application passwords. One, and only one, is all the app needs after all.
///
/// `ApplicationPasswordRepository`'s main responsibility is to ensure only one application password is created.
///
/// We use a singleton for this type, so that we can track all password creation requests in one instance. This
/// prevents multiple application passwords from being created when the function is called repeatedly at the same time.
///
/// Imagine a scenario where a user adds an atomic site as a self-hosted site via the "Entering your existing site address" option.
/// The app automatically creates an application password on the site. Then the user decides to remove the site and sign in
/// with their WP.com account. We want to avoid creating another application password, because the one created before is still
/// usable.
///
/// All created application passwords are stored in a single entry in the Keychain. They are stored as a JSON array, with the
/// structure of `[Entry]`.
/// Each entry has the password value, and the "owner" to whom the password belongs. In practice, all application passwords
/// should be associated with two "owners": one by their Jetpack site ID, and one by the site address. That means the same
/// password can be used no matter whether the site is added to the app via WP.com account, or as a self-hosted site.
///
/// The same application password is also added as a separate Keychain item, to keep `Blog.getApplicationToken`
/// continuing to work as it is. The `createPasswordIfNeeded` function ensures the `Blog.getApplicationToken` returns the valid one.

actor ApplicationPasswordRepository {
    static let shared: ApplicationPasswordRepository = .init(coreDataStack: ContextManager.shared, keychain: KeychainUtils())

    private let coreDataStack: CoreDataStackSwift
    private let storage: ApplicationPasswordStorage
    private var inflightTasks: [TaggedManagedObjectID<Blog>: Task<ApplicationPassword, Error>] = [:]

    static func forTesting(coreDataStack: CoreDataStackSwift, keychain: KeychainAccessible) -> ApplicationPasswordRepository {
        ApplicationPasswordRepository(coreDataStack: coreDataStack, keychain: keychain)
    }

    private init(coreDataStack: CoreDataStackSwift, keychain: KeychainAccessible) {
        self.coreDataStack = coreDataStack
        self.storage = .init(keychain: keychain)
    }

    /// The application password was stored via `Blog.setApplicationToken`, not in the `ApplicationPasswordStorage`.
    /// We want to copy the `Blog.getApplicationToken` to `ApplicationPasswordStorage` if needed.
    func saveApplicationPassword(of blogId: TaggedManagedObjectID<Blog>) async throws {
        let (owners, site) = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogId)
            return (blog.asApplicationPasswordOwners(), try? WordPressSite(blog: blog))
        }

        guard case let .selfHosted(_, apiRootURL, username, authToken) = site else {
            return
        }

        let alreadyStored = await storage
            .passwords(belongTo: owners)
            .contains { $0.password == authToken }
        guard !alreadyStored else { return }

        // No need to propagate the API request error.
        let api = WordPressAPI(
            urlSession: URLSession(configuration: .ephemeral),
            notifyingDelegate: PulseNetworkLogger(),
            apiRootUrl: apiRootURL,
            authentication: .init(username: username, password: authToken)
        )
        guard let uuid = try? await api.applicationPasswords.retrieveCurrentWithViewContext().data.uuid.uuid else { return }

        try await storage.save(.init(password: .init(uuid: uuid, password: authToken), owners: owners))
    }

    /// When returning true, a valid application password is guaranteed to be returned by the `Blog.getApplicationToken` function.
    func createPasswordIfNeeded(for blogId: TaggedManagedObjectID<Blog>) async throws {
        if let _ = try await validatePasswords(in: blogId) {
            return
        }

        // `createPasswordIfNeeded` can be called by multiple callers at the same time. We want to avoid
        // creating multiple application passwords on one site.
        _ = try await waitForInflightTaskIfNeeded(blogId: blogId)
    }

    private func waitForInflightTaskIfNeeded(blogId: TaggedManagedObjectID<Blog>) async throws -> ApplicationPassword {
        if let task = inflightTasks[blogId] {
            switch await waitForInflightTask(task, blogId: blogId) {
            case let .success(value):
                return value
            case let .failure(error):
                throw error
            case .restart:
                // We'll make another attempt to create an application password.
                return try await waitForInflightTaskIfNeeded(blogId: blogId)
            }
        }

        let task = Task {
            try await createPassword(for: blogId)
        }
        inflightTasks[blogId] = task
        defer {
            inflightTasks[blogId] = nil
        }

        // We need to explicitly cancel the created `Task` above.
        // https://forums.swift.org/t/understanding-task-cancellation/75329/2
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func waitForInflightTask(_ inflight: Task<ApplicationPassword, Error>, blogId: TaggedManagedObjectID<Blog>) async -> WaitResult {
        let result = await inflight.result

        // If the current task, which is waiting for the inflight task result, is cancelled, the function should
        // throw a `CancellationError`.
        if Task.isCancelled {
            return .failure(CancellationError())
        }

        return switch result {
            case let .success(value):
                .success(value)
            case let .failure(error):
                // If the inflight task is cancelled, the current Task should start a new call to create an application
                // password.
                if error.isCancellationError() {
                    .restart
                } else {
                    // For other errors, we can still retry, but I don't see the need to do that.
                    .failure(error)
                }
            }
    }
}

private extension ApplicationPasswordRepository {
    func validatePasswords(in blogId: TaggedManagedObjectID<Blog>) async throws -> ApplicationPassword? {
        try await saveApplicationPassword(of: blogId)

        let (owners, siteUrl) = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogId)
            return try (
                blog.asApplicationPasswordOwners(),
                blog.getUrlString(),
            )
        }
        let passwords = await storage.passwords(belongTo: owners)

        let apiRootURL = try await updateRestAPIURLIfNeeded(blogId)
        let siteUsername = try await updateSiteUsernameIfNeeded(blogId)

        let session = URLSession(configuration: .ephemeral)
        var validPasswords = [ApplicationPassword]()
        var invalidPasswords = [ApplicationPassword]()
        for password in passwords {
            let api = WordPressAPI(
                urlSession: session,
                notifyingDelegate: PulseNetworkLogger(),
                apiRootUrl: apiRootURL,
                authentication: .init(username: siteUsername, password: password.password)
            )
            do {
                _ = try await api.applicationPasswords.retrieveCurrentWithViewContext()
                validPasswords.append(password)
            } catch let error as WpApiError {
                if case let .WpError(errorCode, _, _, _) = error {
                    if errorCode == .Unauthorized {
                        invalidPasswords.append(password)
                    }
                }
            }
        }

        if !invalidPasswords.isEmpty {
            try await storage.delete(invalidPasswords)
        }

        DDLogInfo("\(passwords.count) passwords stored for user (\(siteUsername)) on \(siteUrl).")
        DDLogInfo("\(validPasswords.count) have been verified, and \(invalidPasswords.count) invalid ones have been deleted.")

        // Make sure the saved password in `Blog` is one of the valid ones.
        if !validPasswords.isEmpty {
            let saved = try await coreDataStack.performQuery { context in
                let blog = try context.existingObject(with: blogId)
                return try? blog.getApplicationToken()
            }

            var shouldUpdate = saved == nil

            if let saved, !validPasswords.map(\.password).contains(saved) {
                shouldUpdate = true
            }

            if shouldUpdate, let newPassword = validPasswords.first {
                try await assign(newPassword, apiRootURL: apiRootURL, to: blogId)
            }
        }

        return validPasswords.first
    }

    func createPassword(for blogId: TaggedManagedObjectID<Blog>) async throws -> ApplicationPassword {
        // Update `Blog.username` so that we can associate the created password with the site itself, in addition to the Jetpack site ID.
        let siteUsername = try await updateSiteUsernameIfNeeded(blogId)
        let apiRootURL = try await updateRestAPIURLIfNeeded(blogId)

        let (owners, dotComSiteId, dotComApi, dotOrgApi) = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogId)
            return (
                blog.asApplicationPasswordOwners(),
                blog.dotComID,
                blog.account?.wordPressComRestApi,
                WordPressOrgRestApi(blog: blog)
            )
        }

        let parameters: [String: AnyHashable] = [
            "app_id": SelfHostedSiteAuthenticator.wordPressAppId.uuidString(),
            "name": SelfHostedSiteAuthenticator.wordPressAppName
        ]

        let password: ApplicationPassword
        if let dotComApi, let dotComSiteId {
            password = try await createPasswordOnJetpackSites(api: dotComApi, siteid: dotComSiteId.intValue, parameters: parameters)
        } else if let dotOrgApi {
            password = try await createPasswordOnSelfHostedSites(api: dotOrgApi, parameters: parameters)
        } else {
            // This error should never happen since a blog is accessible via either dot-com or a dot-org API.
            throw ApplicationPasswordRepositoryError.unknown
        }

        try await storage.save(.init(password: password, owners: owners))
        try await assign(password, apiRootURL: apiRootURL, to: blogId)

        DDLogInfo("Application password is created for user \(siteUsername) to access REST API at \(apiRootURL)")

        Task { @MainActor in
            NotificationCenter.default.post(name: SelfHostedSiteAuthenticator.applicationPasswordUpdated, object: nil)
        }

        return password
    }

    // When a site is fully connected to Jetpack (a.k.a, "user connection"), we can use the Jetpack Proxy endpoint to
    // call its REST API.
    func createPasswordOnJetpackSites(api: WordPressComRestApi, siteid: Int, parameters: [String: AnyHashable]) async throws -> ApplicationPassword {
        let remote = JetpackProxyServiceRemote(wordPressComRestApi: api)
        let result = try await withCheckedThrowingContinuation { continuation in
            remote.proxyRequest(
                for: siteid,
                path: "/wp/v2/users/me/application-passwords",
                method: .post,
                parameters: parameters
            ) { result in
                continuation.resume(with: result)
            }
        }

        let json = try JSONSerialization.data(withJSONObject: result, options: [])
        struct Response: Decodable {
            var data: ApplicationPassword
        }

        return try JSONDecoder().decode(Response.self, from: json).data
    }

    // For sites that are not on WP.com, we try to create an application password via wp-json REST API using `WordPressOrgRestApi`.
    func createPasswordOnSelfHostedSites(api: WordPressOrgRestApi, parameters: [String: AnyHashable]) async throws -> ApplicationPassword {
        // WordPressOrgRestApi uses cookie and nonce authentication to access the wp-json REST API. Cookies are
        // obtained by simulating wp-login with the site's username and password, and the nonce is fetched from wp-admin.
        // Some sites may block these authentication requests. We verify REST API accessibility before attempting
        // to create the application password and throw an appropriate error if access fails.
        do {
            let _ = try await api.get(path: "/wp/v2/users/me", parameters: ["context": "edit"]).get()
        } catch {
            switch error {
            case let .endpointError(error) where error.code == "rest_not_logged_in":
                fallthrough
            case .unparsableResponse, .unacceptableStatusCode:
                throw ApplicationPasswordRepositoryError.restApiInaccessible
            default:
                break
            }
        }

        let result = try await api.post(path: "/wp/v2/users/me/application-passwords", parameters: parameters).get()
        let json = try JSONSerialization.data(withJSONObject: result, options: [])
        return try JSONDecoder().decode(ApplicationPassword.self, from: json)
    }

    func assign(_ password: ApplicationPassword, apiRootURL: ParsedUrl, to blogId: TaggedManagedObjectID<Blog>) async throws {
        _ = try await updateSiteUsernameIfNeeded(blogId)

        let keychain = await storage.keychain
        try await coreDataStack.performAndSave { context in
            let blog = try context.existingObject(with: blogId)
            blog.restApiRootURL = apiRootURL.url()
            try blog.setApplicationToken(password.password, using: keychain)
        }
    }

    func updateRestAPIURLIfNeeded(_ blogId: TaggedManagedObjectID<Blog>) async throws -> ParsedUrl {
        let (siteUrl, restApiRootUrl) = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogId)
            return try (blog.getUrlString(), blog.restApiRootURL)
        }

        let session = URLSession(configuration: .ephemeral)
        let loginClient = WordPressLoginClient(urlSession: session)
        let apiRootURL: ParsedUrl
        if let restApiRootUrl, let parsed = try? ParsedUrl.parse(input: restApiRootUrl) {
            apiRootURL = parsed
        } else {
            apiRootURL = try await loginClient.details(ofSite: siteUrl).apiRootUrl

            try await coreDataStack.performAndSave { context in
                let blog = try context.existingObject(with: blogId)
                blog.restApiRootURL = apiRootURL.url()
            }
        }

        return apiRootURL
    }

    func updateSiteUsernameIfNeeded(_ blogId: TaggedManagedObjectID<Blog>) async throws -> String {
        let (username, dotComId, dotComAuthToken) = try await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: blogId)
            return (
                blog.username,
                blog.dotComID,
                blog.account?.authToken,
            )
        }

        let siteUsername: String
        if let username {
            siteUsername = username
        } else if let dotComId, let dotComAuthToken {
            let site = WordPressSite.dotCom(siteId: dotComId.intValue, authToken: dotComAuthToken)
            let client = WordPressClient(site: site)
            siteUsername = try await client.api.users.retrieveMeWithEditContext().data.username
            try await coreDataStack.performAndSave { context in
                let blog = try context.existingObject(with: blogId)
                blog.username = siteUsername
            }
        } else {
            throw ApplicationPasswordRepositoryError.usernameNotFound
        }

        return siteUsername
    }
}

private extension Blog {
    func asApplicationPasswordOwners() -> [ApplicationPasswordOwner] {
        var owners = [ApplicationPasswordOwner]()
        if let account, let siteId = dotComID?.intValue {
            owners.append(.dotCom(username: account.username, siteId: siteId))
        }
        if let username, let url {
            owners.append(.selfHosted(username: username, site: url))
        }
        return owners
    }
}

// Since all application passwords are saved in one entry, it's very easy to overwrite them when multiple writes happen at the same time.
// We use an `actor` type here and expose individual write functions to avoid that problem.
private actor ApplicationPasswordStorage {
    // IMPORTANT: DO NOT CHANGE these values.
    private let username = "ApplicationPasswords"
    private let service = "com.automattic.sites.ApplicationPasswords"

    let keychain: KeychainAccessible

    init(keychain: KeychainAccessible) {
        self.keychain = keychain
    }

    func save(_ entry: Entry) throws {
        var entries = getAll()
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        try saveAll(entries)
    }

    func delete(_ passwords: [ApplicationPassword]) throws {
        guard !passwords.isEmpty else { return }

        let uuids = passwords.reduce(into: Set()) { $0.insert($1.uuid) }
        var entries = getAll()
        entries.removeAll { uuids.contains($0.password.uuid) }
        try saveAll(entries)
    }

    func getAll() -> [Entry] {
        guard let value = try? keychain.getPassword(for: username, serviceName: service) else {
            return []
        }

        return (try? JSONDecoder().decode([Entry].self, from: Data(value.utf8))) ?? []
    }

    private func saveAll(_ entries: [Entry]) throws {
        let data = try JSONEncoder().encode(entries)
        try keychain.setPassword(for: username, to: String(data: data, encoding: .utf8), serviceName: service)
    }
}

extension ApplicationPasswordStorage {
    func passwords(belongTo owners: [ApplicationPasswordOwner]) -> [ApplicationPassword] {
        getAll()
            // This nested loop should not have too much negative impact on performance, since `owners` is a short list (2 elements).
            .filter { $0.owners.contains { owners.contains($0) } }
            .map { $0.password }
    }
}

enum ApplicationPasswordRepositoryError: LocalizedError {
    case usernameNotFound
    case restApiInaccessible
    case unknown

    var errorDescription: String? {
        switch self {
        case .usernameNotFound:
            return NSLocalizedString(
                "applicationPasswordRepository.error.usernameNotFound",
                value: "Unable to find username for the site",
                comment: "Error message when the username cannot be found for application password creation"
            )
        case .restApiInaccessible:
            return NSLocalizedString(
                "applicationPasswordRepository.error.restApiInaccessible",
                value: "Unable to access the site's REST API",
                comment: "Error message when the site's REST API is not accessible for application password creation"
            )
        case .unknown:
            return NSLocalizedString(
                "applicationPasswordRepository.error.unknown",
                value: "Unable to create application password",
                comment: "Error message when application password creation fails for unknown reasons"
            )
        }
    }
}

// MARK: - Keychain data storage

/// IMPORTANT: Changing properties in the following types means we may need to migrate the stored data to the new type.
private struct Entry: Codable, Identifiable {
    var password: ApplicationPassword
    var owners: [ApplicationPasswordOwner]

    var id: String {
        password.uuid
    }
}

private struct ApplicationPassword: Codable {
    var uuid: String
    var password: String
}

private enum ApplicationPasswordOwner: Codable, Hashable {
    case dotCom(username: String, siteId: Int)
    case selfHosted(username: String, site: String)
}

private enum WaitResult {
    case success(ApplicationPassword)
    case failure(Error)
    case restart
}
