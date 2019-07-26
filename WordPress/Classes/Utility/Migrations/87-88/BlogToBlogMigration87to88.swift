import CoreData

class BlogToBlogMigration87to88: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)

        let isGutenbergEnabled = UserDefaults.standard.object(forKey: "kUserDefaultsGutenbergEditorEnabled") as? Bool ?? false
        let editor = isGutenbergEnabled ? "gutenberg" : "aztec"

        dInstance.setValue(editor, forKey: "mobileEditor")
    }
}
