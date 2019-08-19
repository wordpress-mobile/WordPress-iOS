import CoreData

class BlogToBlogMigration87to88: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)

        let gutenbergEnabledFlag = UserDefaults.standard.object(forKey: "kUserDefaultsGutenbergEditorEnabled") as? Bool
        let isGutenbergEnabled = gutenbergEnabledFlag ?? false
        let editor = isGutenbergEnabled ? "gutenberg" : "aztec"

        dInstance.setValue(editor, forKey: "mobileEditor")

        if gutenbergEnabledFlag != nil {
            let url = dInstance.value(forKey: "url") as? String ?? ""
            let perSiteEnabledKey = "com.wordpress.gutenberg-autoenabled-"+url
            UserDefaults.standard.set(true, forKey: perSiteEnabledKey)
        }
    }

    override func end(_ mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        NotificationCenter.default.observeOnce(forName: .applicationLaunchCompleted, object: nil, queue: .main, using: { (_) in
            let context = ContextManager.shared.mainContext
            let service = EditorSettingsService(managedObjectContext: context)
            let isGutenbergEnabled = UserDefaults.standard.object(forKey: "kUserDefaultsGutenbergEditorEnabled") as? Bool ?? false

            service.migrateGlobalSettingToRemote(isGutenbergEnabled: isGutenbergEnabled)
        })
    }
}
