import Foundation
import WordPressData
import WordPressKit
import WordPressKitObjC
import WordPressShared
import WordPressCore

enum BlogSettingsServiceError: Error {
    case unknown
    case allSourcesFailed
    case missingSiteID
    case noAvailableTransport
}

extension BlogService {
    @objc(fetchAndPersistSettingsForBlog:completion:)
    public func fetchAndPersistSettings(for blog: Blog, completion: ((Error?) -> Void)?) {
        // Capture the ID synchronously on the caller's context; the async work
        // must not capture the `blog` managed object across contexts.
        let blogID = TaggedManagedObjectID(blog)
        Task { @MainActor in
            do {
                try await fetchAndPersistSettings(for: blogID)
                completion?(nil)
            } catch {
                completion?(error)
            }
        }
    }

    private func fetchAndPersistSettings(for blogID: TaggedManagedObjectID<Blog>) async throws {
        let source = try await settingsSource(for: blogID)

        switch source {
        case .wpcom(let remote):
            let settings = try await fetchSettings(remote)
            await persistSettings(settings, for: blogID)
        case .coreREST(let primaryRemote, let complementRemote):
            async let primary = try? fetchSettings(primaryRemote)
            async let complement = fetchOptionalSettings(complementRemote)

            let fetched = await (primary: primary, complement: complement)
            guard let settings = combinedSettings(primary: fetched.primary, complement: fetched.complement) else {
                throw BlogSettingsServiceError.allSourcesFailed
            }
            await persistSettings(settings, for: blogID)
        case .xmlrpc(let remote):
            let settings = try await fetchSettings(remote)
            await persistSettings(settings, for: blogID)
        case .missingSiteID:
            throw BlogSettingsServiceError.missingSiteID
        case .none:
            return
        }
    }

    /// Combines the two payloads of the only fetch path with more than one source:
    /// an application-password site, where the Core REST primary omits `privacy`
    /// that the XML-RPC options (complement) still carry. The primary always wins;
    /// the complement only fills the handful of fields it can provide (name,
    /// tagline, privacy, see `RemoteBlogOptionsHelper`). Returns nil only when both
    /// sources are nil. Single-source paths skip this and persist their one payload
    /// directly, so the snapshot write in `-[BlogService updateSettings:withRemoteSettings:]`
    /// is the only merge other sites see.
    private func combinedSettings(
        primary: RemoteBlogSettings?,
        complement: RemoteBlogSettings?
    ) -> RemoteBlogSettings? {
        guard let primary else {
            return complement
        }
        guard let complement else {
            return primary
        }
        primary.name = primary.name ?? complement.name
        primary.tagline = primary.tagline ?? complement.tagline
        primary.privacy = primary.privacy ?? complement.privacy
        return primary
    }

    @MainActor
    func settingsSource(
        for blogID: TaggedManagedObjectID<Blog>,
        keychain: KeychainAccessible = AppKeychain()
    ) throws -> SettingsSource {
        // Resolve the blog on the main context here (on the main actor) so the
        // remotes are built from a managed object bound to a known context. The
        // remotes capture value-typed credentials, so they're safe to use from the
        // async fetches that follow.
        let blog = try coreDataStack.mainContext.existingObject(with: blogID)
        if blog.supports(.wpComRESTAPI), let api = blog.wordPressComRestApi {
            guard let dotComID = blog.dotComID else {
                return .missingSiteID
            }
            return .wpcom(BlogServiceRemoteREST(wordPressComRestApi: api, siteID: dotComID))
        }

        if let coreREST = BlogServiceRemoteCoreREST(blog: blog, keychain: keychain) {
            let complement = xmlrpcRemote(for: blog)
            return .coreREST(primary: coreREST, complement: complement)
        }

        if let xmlrpcRemote = xmlrpcRemote(for: blog) {
            return .xmlrpc(xmlrpcRemote)
        }

        return .none
    }

    private func xmlrpcRemote(for blog: Blog) -> BlogServiceRemoteXMLRPC? {
        // The Objective-C initializer returns nil for missing credentials, which Swift imports as non-optional.
        guard let xmlrpcApi = blog.xmlrpcApi,
            let username = blog.username,
            let password = blog.password
        else {
            return nil
        }

        return BlogServiceRemoteXMLRPC(api: xmlrpcApi, username: username, password: password)
    }

    private func fetchSettings(_ remote: BlogServiceRemoteREST) async throws -> RemoteBlogSettings {
        try await withCheckedThrowingContinuation { continuation in
            remote.syncBlogSettings(
                success: { settings in
                    guard let settings else {
                        continuation.resume(throwing: BlogSettingsServiceError.unknown)
                        return
                    }
                    continuation.resume(returning: settings)
                },
                failure: { error in
                    continuation.resume(throwing: error ?? BlogSettingsServiceError.unknown)
                }
            )
        }
    }

    private func fetchSettings(_ remote: BlogServiceRemoteCoreREST) async throws -> RemoteBlogSettings {
        try await withCheckedThrowingContinuation { continuation in
            remote.syncBlogSettings(
                success: { settings in
                    guard let settings else {
                        continuation.resume(throwing: BlogSettingsServiceError.unknown)
                        return
                    }
                    continuation.resume(returning: settings)
                },
                failure: { error in
                    continuation.resume(throwing: error ?? BlogSettingsServiceError.unknown)
                }
            )
        }
    }

    private func fetchSettings(_ remote: BlogServiceRemoteXMLRPC) async throws -> RemoteBlogSettings {
        try await withCheckedThrowingContinuation { continuation in
            remote.syncBlogOptions(
                success: { options in
                    guard let options else {
                        continuation.resume(throwing: BlogSettingsServiceError.unknown)
                        return
                    }
                    let settings = RemoteBlogOptionsHelper.remoteBlogSettings(
                        fromXMLRPCDictionaryOptions: options as NSDictionary
                    )
                    continuation.resume(returning: settings)
                },
                failure: { error in
                    continuation.resume(throwing: error ?? BlogSettingsServiceError.unknown)
                }
            )
        }
    }

    private func fetchOptionalSettings(_ remote: BlogServiceRemoteXMLRPC?) async -> RemoteBlogSettings? {
        guard let remote else {
            return nil
        }
        return try? await fetchSettings(remote)
    }

    private func persistSettings(
        _ remoteSettings: RemoteBlogSettings,
        for blogID: TaggedManagedObjectID<Blog>
    ) async {
        // The throwing `performAndSave` lives on `CoreDataStackSwift`, but `coreDataStack` here
        // is the base `CoreDataStack`. Rather than downcast to propagate the error (and handle a
        // cast failure that can't realistically happen), we ignore the unlikely blog-resolution failure.
        await coreDataStack.performAndSave { context in
            if let blog = try? context.existingObject(with: blogID), let settings = blog.settings {
                self.update(settings, withRemoteSettings: remoteSettings)
            }
        }
    }
}

enum SettingsSource {
    case wpcom(BlogServiceRemoteREST)
    case coreREST(primary: BlogServiceRemoteCoreREST, complement: BlogServiceRemoteXMLRPC?)
    case xmlrpc(BlogServiceRemoteXMLRPC)
    /// Not reachable in practice: a blog that supports the WP.com REST API always
    /// has a `dotComID`, so the site ID is never missing once that branch is taken.
    case missingSiteID
    /// Not reachable in practice: every blog has at least one usable transport
    /// (WP.com REST, Core REST, or XML-RPC), so a source is always found.
    case none
}

extension BlogService {
    /// Serializes settings writes that can be triggered rapidly from the UI.
    ///
    /// For example, toggling settings in `SharingButtonsViewController` can
    /// call `updateSettings` again before the previous request finishes. A
    /// shared queue preserves the user's change order even when each call uses
    /// a new `BlogService` instance.
    private static let settingsWriteOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "org.wordpress.BlogService.settingsWrites"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    /// Saves the declared settings changes to the blog's transport.
    ///
    /// Callers keep mutating `blog.settings` in memory for immediate UI
    /// feedback and pass the same values here. Only acknowledged changes
    /// are persisted by this path; on failure it persists nothing (pending
    /// in-memory edits share the main context and can still be persisted
    /// by unrelated saves, exactly as before this API existed).
    @objc(updateSettingsForBlog:changes:success:failure:)
    public func updateSettings(
        for blog: Blog,
        changes: BlogSettingsChanges,
        success: (() -> Void)?,
        failure: ((Error) -> Void)?
    ) {
        updateSettings(for: blog, changes: changes, keychain: AppKeychain(), success: success, failure: failure)
    }

    func updateSettings(
        for blog: Blog,
        changes: BlogSettingsChanges,
        keychain: KeychainAccessible,
        success: (() -> Void)?,
        failure: ((Error) -> Void)?
    ) {
        let blogID = TaggedManagedObjectID(blog)
        Self.settingsWriteOperationQueue.addOperation(
            AsyncBlockOperation { operationCompletion in
                Task { @MainActor in
                    defer { operationCompletion() }

                    do {
                        try await self.performSettingsUpdate(for: blogID, changes: changes, keychain: keychain)
                        success?()
                    } catch {
                        failure?(error)
                    }
                }
            }
        )
    }

    @MainActor
    private func performSettingsUpdate(
        for blogID: TaggedManagedObjectID<Blog>,
        changes: BlogSettingsChanges,
        keychain: KeychainAccessible
    ) async throws {
        guard !changes.isEmpty else {
            return
        }

        let sparse = changes.toRemoteBlogSettings()
        let source = try settingsSource(for: blogID, keychain: keychain)

        switch source {
        case .wpcom(let remote):
            try await updateSettings(sparse, via: remote)
        case .coreREST(let primary, _):
            // The XML-RPC complement is read-path-only: the only fields the
            // XML-RPC writer ever handled (title, tagline) are written by
            // Core REST itself.
            try await primary.updateBlogSettings(sparse)
        case .xmlrpc(let remote):
            let options = RemoteBlogOptionsHelper.remoteOptionsForUpdatingBlogTitleAndTagline(sparse) as? [AnyHashable: Any] ?? [:]
            guard !options.isEmpty else {
                // This transport can only write title and tagline; other
                // declared fields are silently unsupported, as they always
                // were. Nothing to send is a success, not an error.
                return
            }
            try await updateOptions(options, via: remote)
        case .missingSiteID, .none:
            throw BlogSettingsServiceError.noAvailableTransport
        }

        // Persist the acknowledged changes on a background context. The cast is
        // safe: ContextManager is the app's only CoreDataStack and conforms to
        // CoreDataStackSwift (see EditorSettingsService for the same pattern).
        // Failure is best-effort: the server write already succeeded, so a local
        // save failure must not turn this save into a failure callback.
        try? await (coreDataStack as! CoreDataStackSwift)
            .performAndSave { context in
                if let blog = try? context.existingObject(with: blogID), let settings = blog.settings {
                    changes.apply(to: settings)
                }
            }
    }

    private func updateSettings(_ settings: RemoteBlogSettings, via remote: BlogServiceRemoteREST) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            remote.update(
                settings,
                success: { continuation.resume() },
                failure: { error in
                    continuation.resume(throwing: error ?? BlogSettingsServiceError.unknown)
                }
            )
        }
    }

    private func updateOptions(_ options: [AnyHashable: Any], via remote: BlogServiceRemoteXMLRPC) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            remote.updateBlogOptions(
                with: options,
                success: { continuation.resume() },
                failure: { error in
                    continuation.resume(throwing: error ?? BlogSettingsServiceError.unknown)
                }
            )
        }
    }
}
