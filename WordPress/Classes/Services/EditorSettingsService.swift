import Foundation

@objc enum EditorSettingsServiceError: Int, Swift.Error {
    case mobileEditorNotSet
}

@objc class EditorSettingsService: LocalCoreDataService {
    let wpcomApi: WordPressComRestApi?

    @objc convenience override init(managedObjectContext: NSManagedObjectContext) {
        self.init(managedObjectContext: managedObjectContext, wpcomApi: nil)
    }

    init(managedObjectContext: NSManagedObjectContext, wpcomApi: WordPressComRestApi? = nil) {
        self.wpcomApi = wpcomApi
        super.init(managedObjectContext: managedObjectContext)
    }

    @objc(syncEditorSettingsForBlog:success:failure:)
    func syncEditorSettings(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        guard
            let api = wpcomApi ?? blog.wordPressComRestApi(),
            let siteID = blog.dotComID?.intValue
        else {
            let error = NSError(domain: "EditorSettingsService", code: 0, userInfo: [NSDebugDescriptionErrorKey: "Api or dotCom Site ID not found"])
            failure(error)
            return
        }

        let service = EditorServiceRemote(wordPressComRestApi: api)
        service.getEditorSettings(siteID, success: { (settings) in
            do {
                try self.saveRemoteEditorSettings(settings, on: blog)
                ContextManager.sharedInstance().save(self.managedObjectContext)
                success()
            } catch EditorSettingsServiceError.mobileEditorNotSet {
                self.migrateLocalSettingToRemote(for: blog, success: success, failure: failure)
            } catch {
                failure(error)
            }
        }, failure: failure)
    }

    private func saveRemoteEditorSettings(_ settings: EditorSettings, on blog: Blog) throws {
        guard settings.mobile != .notSet else {
            throw EditorSettingsServiceError.mobileEditorNotSet
        }
        blog.mobileEditor = settings.mobile.rawValue
        blog.webEditor = settings.web.rawValue
    }

    private func migrateLocalSettingToRemote(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        if blog.editor.mobile == nil {
            let settings = GutenbergSettings()
            let defaultEditor = settings.getDefaultEditor(for: blog)
            settings.setGutenbergEnabled(defaultEditor == .gutenberg, for: blog)
        }
        postEditorSetting(for: blog, success: success, failure: failure)
    }

    func postEditorSetting(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        guard
            let selectedEditor = blog.editor.mobile,
            let remoteEditor = EditorSettings.Mobile(rawValue: selectedEditor.rawValue),
            let api = wpcomApi ?? blog.wordPressComRestApi(),
            let siteID = blog.dotComID?.intValue
        else {
            let error = NSError(domain: "EditorSettingsService", code: 0, userInfo: [NSDebugDescriptionErrorKey: "Api or dotCom Site ID not found"])
            failure(error)
            return
        }
        let service = EditorServiceRemote(wordPressComRestApi: api)
        service.postDesignateMobileEditor(siteID, editor: remoteEditor, success: { _ in
            success()
        }, failure: failure)
    }
}
