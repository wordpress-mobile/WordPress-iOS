import Foundation
import WordPressKit

class BlockEditorSettingsService {
    typealias BlockEditorSettingsServiceCompletion = (_ hasChanges: Bool, _ blockEditorSettings: BlockEditorSettings?) -> Void

    let blog: Blog
    let remote: BlockEditorSettingsServiceRemote
    let context: NSManagedObjectContext

    var cachedSettings: BlockEditorSettings? {
        return blog.blockEditorSettings
    }

    convenience init?(blog: Blog, context: NSManagedObjectContext) {
        let remoteAPI: WordPressRestApi
        if blog.isAccessibleThroughWPCom(),
           blog.dotComID?.intValue != nil,
           let restAPI = blog.wordPressComRestApi() {
            remoteAPI = restAPI
        } else if let orgAPI = blog.wordPressOrgRestApi {
            remoteAPI = orgAPI
        } else {
            // This is should only happen if there is a problem with the blog itsself.
            return nil
        }

        self.init(blog: blog, remoteAPI: remoteAPI, context: context)
    }

    init(blog: Blog, remoteAPI: WordPressRestApi, context: NSManagedObjectContext) {
        self.blog = blog
        self.context = context
        self.remote = BlockEditorSettingsServiceRemote(remoteAPI: remoteAPI)
    }

    func fetchSettings(_ completion: @escaping BlockEditorSettingsServiceCompletion) {
        if blog.supports(.blockEditorSettings) {
            fetchBlockEditorSettings(completion)
        } else {
            fetchTheme(completion)
        }
    }
}

// MARK: Editor `theme_supports` support
private extension BlockEditorSettingsService {
    func fetchTheme(_ completion: @escaping BlockEditorSettingsServiceCompletion) {
        remote.fetchTheme(forSiteID: blog.dotComID?.intValue) { [weak self] (response) in
            guard let `self` = self else { return }
            switch response {
            case .success(let editorTheme):
                self.context.perform {
                    let originalChecksum = self.blog.blockEditorSettings?.checksum ?? ""
                    self.updateEditorThemeCache(originalChecksum: originalChecksum, editorTheme: editorTheme, completion: completion)
                }
            case .failure(let error):
                DDLogError("Error loading active theme: \(error)")
            }
        }
    }

    func updateEditorThemeCache(originalChecksum: String, editorTheme: RemoteEditorTheme?, completion: @escaping BlockEditorSettingsServiceCompletion) {
        let newChecksum = editorTheme?.checksum ?? ""
        guard originalChecksum != newChecksum else {
            /// The fetched Editor Theme is the same as the cached one so respond with no new changes.
            completion(false, self.blog.blockEditorSettings)
            return
        }

        guard let editorTheme = editorTheme else {
            /// The original checksum is different than an empty one so we need to clear the old settings.
            clearCoreData(completion: completion)
            return
        }

        /// The fetched Editor Theme is different than the cached one so persist the new one and delete the old one.
        context.perform {
            self.persistEditorThemeToCoreData(blogID: self.blog.objectID, editorTheme: editorTheme) { success in
                guard success else {
                    completion(false, nil)
                    return
                }

                self.context.perform {
                    completion(true, self.blog.blockEditorSettings)
                }
            }
        }
    }

    func persistEditorThemeToCoreData(blogID: NSManagedObjectID, editorTheme: RemoteEditorTheme, completion: @escaping (_ success: Bool) -> Void) {
        let parsingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        parsingContext.parent = context
        parsingContext.mergePolicy =  NSMergePolicy.mergeByPropertyObjectTrump

        parsingContext.perform {
            guard let blog = parsingContext.object(with: blogID) as? Blog else {
                completion(false)
                return
            }

            if let blockEditorSettings = blog.blockEditorSettings {
                // Block Editor Settings nullify on delete
                parsingContext.delete(blockEditorSettings)
            }

            blog.blockEditorSettings = BlockEditorSettings(editorTheme: editorTheme, context: parsingContext)
            try? parsingContext.save()
            completion(true)
        }
    }
}

// MARK: Editor Global Styles support
private extension BlockEditorSettingsService {
    func fetchBlockEditorSettings(tryExperimental: Bool = false, _ completion: @escaping BlockEditorSettingsServiceCompletion) {
        /*
         * This endpoint was released as part of WP 5.8 with the __experimental flag.
         * Starting with Gutenberg 11.1 the endpoint will be available without the __experimental flag.
         * Gutenberg 11.1 will be included in WP 5.9.
         * These tests just ensure we are using the appropriate endpoints for each scenario based on when this was released.
         *
         * We'll try the non-experimental path first but then if that fails (which should only be for base WP 5.8 installs)
         * then we'll fall back and try the experimental endpoint.
         */
        let hasExperimentalEndpoint = blog.hasRequiredWordPressVersion("5.8") && !blog.hasRequiredWordPressVersion("5.9")
        let requiresExperimental = hasExperimentalEndpoint ? tryExperimental : false

        remote.fetchBlockEditorSettings(forSiteID: blog.dotComID?.intValue, requiresExperimental: requiresExperimental) { [weak self] (response) in
            guard let `self` = self else { return }
            switch response {
            case .success(let remoteSettings):
                self.context.perform {
                    let originalChecksum = self.blog.blockEditorSettings?.checksum ?? ""
                    self.updateBlockEditorSettingsCache(originalChecksum: originalChecksum, remoteSettings: remoteSettings, completion: completion)
                }
            case .failure(let error):
                if !tryExperimental && hasExperimentalEndpoint {
                    self.fetchBlockEditorSettings(tryExperimental: true, completion)
                } else {
                    DDLogError("Error loading Block Editor Settings: \(error)")
                    completion(false, nil)
                }
            }
        }
    }

    func updateBlockEditorSettingsCache(originalChecksum: String, remoteSettings: RemoteBlockEditorSettings?, completion: @escaping BlockEditorSettingsServiceCompletion) {
        let newChecksum = remoteSettings?.checksum ?? ""
        guard originalChecksum != newChecksum else {
            /// The fetched Block Editor Settings is the same as the cached one so respond with no new changes.
            completion(false, self.blog.blockEditorSettings)
            return
        }

        guard let remoteSettings = remoteSettings else {
            /// The original checksum is different than an empty one so we need to clear the old settings.
            clearCoreData(completion: completion)
            return
        }

        /// The fetched Block Editor Settings is different than the cached one so persist the new one and delete the old one.
        context.perform {
            self.persistBlockEditorSettingsToCoreData(blogID: self.blog.objectID, remoteSettings: remoteSettings) { success in
                guard success else {
                    completion(false, nil)
                    return
                }

                self.context.perform {
                    completion(true, self.blog.blockEditorSettings)
                }
            }
        }
    }

    func persistBlockEditorSettingsToCoreData(blogID: NSManagedObjectID, remoteSettings: RemoteBlockEditorSettings, completion: @escaping (_ success: Bool) -> Void) {
        let parsingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        parsingContext.parent = context
        parsingContext.mergePolicy =  NSMergePolicy.mergeByPropertyObjectTrump

        parsingContext.perform {
            guard let blog = parsingContext.object(with: blogID) as? Blog else {
                completion(false)
                return
            }

            if let blockEditorSettings = blog.blockEditorSettings {
                // Block Editor Settings nullify on delete
                parsingContext.delete(blockEditorSettings)
            }

            blog.blockEditorSettings = BlockEditorSettings(remoteSettings: remoteSettings, context: parsingContext)
            try? parsingContext.save()
            completion(true)
        }
    }
}

// MARK: Shared Core Data Support
private extension BlockEditorSettingsService {
    func clearCoreData(completion: @escaping BlockEditorSettingsServiceCompletion) {
        self.context.perform {
            if let blockEditorSettings = self.blog.blockEditorSettings {
                // Block Editor Settings nullify on delete
                self.context.delete(blockEditorSettings)
            }
            completion(true, nil)
        }
    }
}
