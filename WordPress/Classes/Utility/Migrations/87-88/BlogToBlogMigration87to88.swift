import CoreData

class BlogToBlogMigration87to88: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)

        guard let sourceBlog = manager.sourceInstances(forEntityMappingName: "BlogToBlog", destinationInstances: [dInstance]).first else {
            return
        }

        let editor: MobileEditor

        if let isGutenbergEnabled = UserDefaults.standard.object(forKey: GutenbergSettings.Key.appWideEnabled) as? Bool {
            // Keep previous user selection
            editor = isGutenbergEnabled ? .gutenberg : .aztec
        } else {
            let isAccessibleThroughWPCom = sourceBlog.value(forKey: "account") != nil
            // Default to Gutenberg for WPCom/Jetpack sites
            editor = isAccessibleThroughWPCom ? .gutenberg : .aztec
        }

        dInstance.setValue(editor.rawValue, forKey: "mobileEditor")
    }
}
