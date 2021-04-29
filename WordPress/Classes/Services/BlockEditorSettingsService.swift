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
        fetchTheme(completion)
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
            /// The original checksum is different than an empty one so we need to claer the old settings.
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
// ToDo: Add support for Global Styles https://github.com/wordpress-mobile/gutenberg-mobile/issues/3163
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
