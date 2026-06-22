import Foundation
import WordPressData
import WordPressKit
import WordPressKitObjC
import WordPressShared
import WordPressCore

enum BlogSettingsFetchError: Error {
    case unknown
    case allSourcesFailed
    case missingSiteID
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
        let source = try await settingsFetchSource(for: blogID)

        switch source {
        case .wpcom(let remote):
            let settings = try await fetchSettings(remote)
            await persistSettings(settings, for: blogID)
        case .coreREST(let primaryRemote, let complementRemote):
            async let primary = try? fetchSettings(primaryRemote)
            async let complement = fetchOptionalSettings(complementRemote)

            let fetched = await (primary: primary, complement: complement)
            guard let settings = combinedSettings(primary: fetched.primary, complement: fetched.complement) else {
                throw BlogSettingsFetchError.allSourcesFailed
            }
            await persistSettings(settings, for: blogID)
        case .xmlrpc(let remote):
            let settings = try await fetchSettings(remote)
            await persistSettings(settings, for: blogID)
        case .missingSiteID:
            throw BlogSettingsFetchError.missingSiteID
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
    private func settingsFetchSource(for blogID: TaggedManagedObjectID<Blog>) throws -> SettingsFetchSource {
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

        if let coreREST = BlogServiceRemoteCoreREST(blog: blog) {
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
                        continuation.resume(throwing: BlogSettingsFetchError.unknown)
                        return
                    }
                    continuation.resume(returning: settings)
                },
                failure: { error in
                    continuation.resume(throwing: error ?? BlogSettingsFetchError.unknown)
                }
            )
        }
    }

    private func fetchSettings(_ remote: BlogServiceRemoteCoreREST) async throws -> RemoteBlogSettings {
        try await withCheckedThrowingContinuation { continuation in
            remote.syncBlogSettings(
                success: { settings in
                    guard let settings else {
                        continuation.resume(throwing: BlogSettingsFetchError.unknown)
                        return
                    }
                    continuation.resume(returning: settings)
                },
                failure: { error in
                    continuation.resume(throwing: error ?? BlogSettingsFetchError.unknown)
                }
            )
        }
    }

    private func fetchSettings(_ remote: BlogServiceRemoteXMLRPC) async throws -> RemoteBlogSettings {
        try await withCheckedThrowingContinuation { continuation in
            remote.syncBlogOptions(
                success: { options in
                    guard let options else {
                        continuation.resume(throwing: BlogSettingsFetchError.unknown)
                        return
                    }
                    let settings = RemoteBlogOptionsHelper.remoteBlogSettings(
                        fromXMLRPCDictionaryOptions: options as NSDictionary
                    )
                    continuation.resume(returning: settings)
                },
                failure: { error in
                    continuation.resume(throwing: error ?? BlogSettingsFetchError.unknown)
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

private enum SettingsFetchSource {
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
