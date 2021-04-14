import Foundation
import WordPressKit

class BlockEditorSettingsService {
    typealias BlockEditorSettingsServiceCompletion = (_ hasChanges: Bool, _ blockEditorSettings: BlockEditorSettings?) -> Void

    let blog: Blog
    let remoteAPI: WordPressRestApi
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
        self.remoteAPI = remoteAPI
        self.context = context
    }

    func fetchSettings(_ completion: @escaping BlockEditorSettingsServiceCompletion) {
        fetchTheme(completion)
    }
}

// MARK: Editor `theme_supports` support
private extension BlockEditorSettingsService {
    func fetchTheme(_ completion: @escaping BlockEditorSettingsServiceCompletion) {
        let requestPath = "/wp/v2/themes?status=active"
        let modifiedPath = remoteAPI.requestPath(fromOrgPath: requestPath, with: blog.dotComID?.intValue)
        remoteAPI.GET(modifiedPath, parameters: nil) { [weak self] (result, _) in
            guard let `self` = self else { return }
            switch result {
            case .success(let response):
                self.processResponse(response) { editorTheme in
                    self.context.perform {
                        let originalChecksum = self.blog.blockEditorSettings?.checksum ?? ""
                        self.updateCache(originalChecksum: originalChecksum, editorTheme: editorTheme, completion: completion)
                    }
                }
            case .failure(let error):
                DDLogError("Error loading active theme: \(error)")
            }
        }
    }

    func processResponse(_ response: Any, completion: (_ editorTheme: EditorTheme?) -> Void) {
        guard let responseData = try? JSONSerialization.data(withJSONObject: response, options: []),
              let editorThemes = try? JSONDecoder().decode([EditorTheme].self, from: responseData) else {
            completion(nil)
            return
        }
        completion(editorThemes.first)
    }

    func updateCache(originalChecksum: String, editorTheme: EditorTheme?, completion: @escaping BlockEditorSettingsServiceCompletion) {
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
            self.persistToCoreData(blogID: self.blog.objectID, editorTheme: editorTheme) { success in
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

    func persistToCoreData(blogID: NSManagedObjectID, editorTheme: EditorTheme, completion: @escaping (_ success: Bool) -> Void) {
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
