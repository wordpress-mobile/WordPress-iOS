import CoreData

class BlogToBlogMigration87to88: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        DDLogInfo("---> \(type(of: self)) \(#function) \(String(describing: mapping.sourceEntityName)) -> \(String(describing: mapping.destinationEntityName)))")

        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)

        guard let sourceBlog = manager.sourceInstances(forEntityMappingName: "BlogToBlog", destinationInstances: [dInstance]).first else {
            return
        }

        let editor: MobileEditor

        if let isGutenbergEnabled = UserDefaults.standard.object(forKey: GutenbergSettings.Key.appWideEnabled) as? Bool {
            editor = isGutenbergEnabled ? .gutenberg : .aztec
        } else {
            let isWPcom = sourceBlog.value(forKeyPath: "account.isWpcom") as? Bool ?? false
            let isJetpack = sourceBlog.value(forKey: "isJetpack") as? Bool ?? false
            let isAccessibleThroughWPCom = isWPcom || isJetpack
            editor = isAccessibleThroughWPCom ? .gutenberg : .aztec
        }

        dInstance.setValue(editor.rawValue, forKey: "mobileEditor")
    }
}
