import Foundation
import WordPressKit

class BlockEditorSettingsService {
    struct SettingsServiceResult {
        let hasChanges: Bool
        let blockEditorSettings: BlockEditorSettings?
    }

    enum BlockEditorSettingsServiceError: Int, Error {
        case blogNotFound
    }

    typealias BlockEditorSettingsServiceCompletion = (Swift.Result<SettingsServiceResult, Error>) -> Void

    let blog: Blog
    let remote: BlockEditorSettingsServiceRemote
    let coreDataStack: CoreDataStackSwift

    var cachedSettings: BlockEditorSettings? {
        return blog.blockEditorSettings
    }

    convenience init?(blog: Blog, coreDataStack: CoreDataStackSwift) {
        guard let remoteAPI = WordPressOrgRestApi(blog: blog) else {
            // This is should only happen if there is a problem with the blog itsself.
            return nil
        }

        self.init(blog: blog, remoteAPI: remoteAPI, coreDataStack: coreDataStack)
    }

    init(blog: Blog, remoteAPI: WordPressOrgRestApi, coreDataStack: CoreDataStackSwift) {
        assert(blog.objectID.persistentStore != nil, "The blog instance should be saved first")
        self.blog = blog
        self.coreDataStack = coreDataStack
        self.remote = BlockEditorSettingsServiceRemote(remoteAPI: remoteAPI)
    }

    func fetchSettings(_ completion: @escaping BlockEditorSettingsServiceCompletion) {
        if blog.supports(.blockEditorSettings) {
            fetchBlockEditorSettings(completion)
        } else {
            fetchTheme(completion)
        }
    }

    @MainActor
    func fetchSettings() async -> Result<SettingsServiceResult, Error> {
        await withCheckedContinuation { continuation in
            fetchSettings { result in
                continuation.resume(returning: result)
            }
        }
    }
}

// MARK: Editor `theme_supports` support
private extension BlockEditorSettingsService {
    func fetchTheme(_ completion: @escaping BlockEditorSettingsServiceCompletion) {
        remote.fetchTheme { [weak self] (response) in
            guard let `self` = self else { return }
            switch response {
            case .success(let editorTheme):
                self.blog.managedObjectContext?.perform {
                    let originalChecksum = self.blog.blockEditorSettings?.checksum ?? ""
                    self.track(isBlockEditorSettings: false, isFSE: false)
                    self.updateEditorThemeCache(originalChecksum: originalChecksum, editorTheme: editorTheme, completion: completion)
                }
            case .failure(let err):
                DDLogError("Error loading active theme: \(err)")
                completion(.failure(err))
            }
        }
    }

    func updateEditorThemeCache(originalChecksum: String, editorTheme: RemoteEditorTheme?, completion: @escaping BlockEditorSettingsServiceCompletion) {
        let newChecksum = editorTheme?.checksum ?? ""
        guard originalChecksum != newChecksum else {
            /// The fetched Editor Theme is the same as the cached one so respond with no new changes.
            let result = SettingsServiceResult(hasChanges: false, blockEditorSettings: self.blog.blockEditorSettings)
            completion(.success(result))
            return
        }

        guard let editorTheme = editorTheme else {
            /// The original checksum is different than an empty one so we need to clear the old settings.
            clearCoreData(completion: completion)
            return
        }

        /// The fetched Editor Theme is different than the cached one so persist the new one and delete the old one.
        self.persistEditorThemeToCoreData(blogID: self.blog.objectID, editorTheme: editorTheme) { callback in
            switch callback {
            case .success:
                let result = SettingsServiceResult(hasChanges: true, blockEditorSettings: self.blog.blockEditorSettings)
                completion(.success(result))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func persistEditorThemeToCoreData(blogID: NSManagedObjectID, editorTheme: RemoteEditorTheme, completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        coreDataStack.performAndSave({ context in
            guard let blog = context.object(with: blogID) as? Blog else {
                throw BlockEditorSettingsServiceError.blogNotFound
            }

            if let blockEditorSettings = blog.blockEditorSettings {
                // Block Editor Settings nullify on delete
                context.delete(blockEditorSettings)
            }

            blog.blockEditorSettings = BlockEditorSettings(editorTheme: editorTheme, context: context)
        }, completion: completion, on: .main)
    }
}

// MARK: Editor Global Styles support
private extension BlockEditorSettingsService {
    func fetchBlockEditorSettings(_ completion: @escaping BlockEditorSettingsServiceCompletion) {
        remote.fetchBlockEditorSettings { [weak self] (response) in
            guard let `self` = self else { return }
            switch response {
            case .success(let remoteSettings):
                self.blog.managedObjectContext?.perform {
                    let originalChecksum = self.blog.blockEditorSettings?.checksum ?? ""
                    self.track(isBlockEditorSettings: true, isFSE: remoteSettings?.isFSETheme ?? false)
                    self.updateBlockEditorSettingsCache(originalChecksum: originalChecksum, remoteSettings: remoteSettings, completion: completion)
                }
            case .failure(let err):
                DDLogError("Error fetching editor settings: \(err)")
                // The user may not have the gutenberg plugin installed so try /wp/v2/themes to maintain feature support.
                // In WP 5.9 we may be able to skip this attempt.
                self.fetchTheme(completion)
            }
        }
    }

    func updateBlockEditorSettingsCache(originalChecksum: String, remoteSettings: RemoteBlockEditorSettings?, completion: @escaping BlockEditorSettingsServiceCompletion) {
        let newChecksum = remoteSettings?.checksum ?? ""
        guard originalChecksum != newChecksum else {
            /// The fetched Block Editor Settings is the same as the cached one so respond with no new changes.
            let result = SettingsServiceResult(hasChanges: false, blockEditorSettings: self.blog.blockEditorSettings)
            completion(.success(result))
            return
        }

        guard let remoteSettings = remoteSettings else {
            /// The original checksum is different than an empty one so we need to clear the old settings.
            clearCoreData(completion: completion)
            return
        }

        /// The fetched Block Editor Settings is different than the cached one so persist the new one and delete the old one.
        self.persistBlockEditorSettingsToCoreData(blogID: self.blog.objectID, remoteSettings: remoteSettings) { callback in
            switch callback {
            case .success:
                let result = SettingsServiceResult(hasChanges: true, blockEditorSettings: self.blog.blockEditorSettings)
                completion(.success(result))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func persistBlockEditorSettingsToCoreData(blogID: NSManagedObjectID, remoteSettings: RemoteBlockEditorSettings, completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        coreDataStack.performAndSave({ context in
            guard let blog = context.object(with: blogID) as? Blog else {
                throw BlockEditorSettingsServiceError.blogNotFound
            }

            if let blockEditorSettings = blog.blockEditorSettings {
                // Block Editor Settings nullify on delete
                context.delete(blockEditorSettings)
            }

            blog.blockEditorSettings = BlockEditorSettings(remoteSettings: remoteSettings, context: context)
        }, completion: completion, on: .main)
    }
}

// MARK: Shared Events
private extension BlockEditorSettingsService {
    func clearCoreData(completion: @escaping BlockEditorSettingsServiceCompletion) {
        coreDataStack.performAndSave({ context in
            guard let blogInContext = try? context.existingObject(with: self.blog.objectID) as? Blog else {
                return
            }
            if let blockEditorSettings = blogInContext.blockEditorSettings {
                // Block Editor Settings nullify on delete
                context.delete(blockEditorSettings)
            }
        }, completion: {
            let result = SettingsServiceResult(hasChanges: true, blockEditorSettings: nil)
            completion(.success(result))
        }, on: .main)
    }

    func track(isBlockEditorSettings: Bool, isFSE: Bool) {
        let endpoint = isBlockEditorSettings ? "wp-block-editor" : "theme_supports"
        let properties: [AnyHashable: Any] = ["endpoint": endpoint,
                                              "full_site_editing": "\(isFSE)"]
        WPAnalytics.track(.gutenbergEditorSettingsFetched, properties: properties)
    }
}
