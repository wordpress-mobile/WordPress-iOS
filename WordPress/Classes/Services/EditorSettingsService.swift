import Foundation

@objc enum EditorSettingsServiceError: Int, Swift.Error {
    case mobileEditorNotSet
}

@objc class EditorSettingsService: LocalCoreDataService {
    @objc(syncEditorSettingsForBlog:success:failure:)
    func syncEditorSettings(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        guard let api = api(for: blog) else {
            // SelfHosted non-jetpack sites won't sync with remote.
            return success()
        }
        guard let siteID = blog.dotComID?.intValue else {
            let error = NSError(domain: "EditorSettingsService", code: 0, userInfo: [NSDebugDescriptionErrorKey: "dotCom Site ID not found"])
            return failure(error)
        }

        let service = EditorServiceRemote(wordPressComRestApi: api)
        service.getEditorSettings(siteID, success: { (settings) in
            do {
                try self.update(blog, remoteEditorSettings: settings)
                ContextManager.sharedInstance().save(self.managedObjectContext)
                success()
            } catch EditorSettingsServiceError.mobileEditorNotSet {
                self.migrateLocalSettingToRemote(for: blog, success: success, failure: failure)
            } catch {
                failure(error)
            }
        }, failure: failure)
    }

    private func update(_ blog: Blog, remoteEditorSettings settings: EditorSettings) throws {
        blog.webEditor = WebEditor(rawValue: settings.web.rawValue)
        guard settings.mobile != .notSet else {
            throw EditorSettingsServiceError.mobileEditorNotSet
        }
        blog.mobileEditor = MobileEditor(rawValue: settings.mobile.rawValue)
    }

    private func migrateLocalSettingToRemote(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        if blog.mobileEditor == nil {
            let settings = GutenbergSettings()
            let defaultEditor = settings.getDefaultEditor(for: blog)
            settings.setGutenbergEnabled(defaultEditor == .gutenberg, for: blog)
        }
        postEditorSetting(for: blog, success: success, failure: failure)
    }

    func postEditorSetting(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        guard
            let selectedEditor = blog.mobileEditor,
            let remoteEditor = EditorSettings.Mobile(rawValue: selectedEditor.rawValue),
            let api = api(for: blog),
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

    func api(for blog: Blog) -> WordPressComRestApi? {
        return blog.wordPressComRestApi()
    }
}
