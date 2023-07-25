import Foundation
import WordPressKit

@objc enum EditorSettingsServiceError: Int, Swift.Error {
    case mobileEditorNotSet
}

@objc class EditorSettingsService: CoreDataService {

    private lazy var coreDataStackSwift: CoreDataStackSwift = {
        // The concrete type of coreDataStack is actually ContextManager, which also conforms to CoreDataStackSwift.
        (coreDataStack as? CoreDataStackSwift) ?? ContextManager.shared
    }()

    @objc(syncEditorSettingsForBlog:success:failure:)
    func syncEditorSettings(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        guard let api = api(for: blog) else {
            // SelfHosted non-jetpack sites won't sync with remote.
            return success()
        }
        guard let siteID = blog.dotComID?.intValue else {
            assertionFailure("Blog with dotCom Rest API but dotCom Site ID not found")
            let error = NSError(domain: "EditorSettingsService", code: 0, userInfo: [NSDebugDescriptionErrorKey: "dotCom Site ID not found"])
            return failure(error)
        }

        let service = EditorServiceRemote(wordPressComRestApi: api)
        service.getEditorSettings(siteID, success: { (settings) in
            self.coreDataStackSwift.performAndSave({ context in
                let blogInContext = try context.existingObject(with: blog.objectID) as! Blog
                try self.update(blogInContext, remoteEditorSettings: settings)
            }, completion: { result in
                switch result {
                case .success:
                    success()
                case .failure(EditorSettingsServiceError.mobileEditorNotSet):
                    self.migrateLocalSettingToRemote(for: blog, success: success, failure: failure)
                case let .failure(error):
                    failure(error)
                }
            }, on: .main)
        }, failure: failure)
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

    /// This method is intended to be called only after the db 87 to 88 migration
    ///
    func migrateGlobalSettingToRemote(isGutenbergEnabled: Bool, overrideRemote: Bool = false, onSuccess: (() -> Void)? = nil) {
        guard let api = apiForDefaultAccount else {
            // SelfHosted non-jetpack sites won't sync with remote.
            return
        }

        let remoteEditor: EditorSettings.Mobile = isGutenbergEnabled ? .gutenberg : .aztec

        let service = EditorServiceRemote(wordPressComRestApi: api)
        service.postDesignateMobileEditorForAllSites(remoteEditor, setOnlyIfEmpty: !overrideRemote, success: { response in
            self.updateAllSites(with: response, completion: onSuccess)
        }) { (error) in
            DDLogError("Error saving editor settings: \(error)")
        }
    }

    func api(for blog: Blog) -> WordPressComRestApi? {
        return blog.wordPressComRestApi()
    }

    var apiForDefaultAccount: WordPressComRestApi? {
        coreDataStack.performQuery { context in
            let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
            return account?.wordPressComRestApi
        }
    }
}

private extension EditorSettingsService {
    func updateAllSites(with response: [Int: EditorSettings.Mobile], completion: (() -> Void)?) {
        coreDataStack.performAndSave({ context in
            guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) else {
                return
            }
            let settings = GutenbergSettings()
            for (siteID, editor) in response {
                self.updateSite(withID: siteID, editor: editor, account: account, settings: settings)
            }
        }, completion: completion, on: .main)
    }

    func updateSite(withID siteID: Int, editor: EditorSettings.Mobile, account: WPAccount, settings: GutenbergSettings) {
        if let blog = account.blogs.first(where: { $0.dotComID?.intValue == siteID }) {
            settings.setGutenbergEnabled(editor == .gutenberg, for: blog)
        }
    }

    func update(_ blog: Blog, remoteEditorSettings settings: EditorSettings) throws {
        blog.webEditor = WebEditor(rawValue: settings.web.rawValue)
        guard settings.mobile != .notSet else {
            throw EditorSettingsServiceError.mobileEditorNotSet
        }
        GutenbergSettings().setGutenbergEnabled(settings.mobile == .gutenberg, for: blog)
    }

    func migrateLocalSettingToRemote(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        if blog.mobileEditor == nil {
            let settings = GutenbergSettings()
            let defaultEditor = settings.getDefaultEditor(for: blog)
            settings.setGutenbergEnabled(defaultEditor == .gutenberg, for: blog)
        }
        postEditorSetting(for: blog, success: success, failure: failure)
    }
}
