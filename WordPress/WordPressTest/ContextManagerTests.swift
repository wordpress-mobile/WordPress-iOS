import Foundation
import XCTest
import CoreData

class ContextManagerTests: XCTestCase {
    var contextManager:TestContextManager!

    override func setUp() {
        super.setUp()
        
        contextManager = TestContextManager()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testIterativeMigration() {
        let model19Url = self.urlForModelName("WordPress 19")
        let model = NSManagedObjectModel(contentsOfURL: model19Url!)
        var psc = NSPersistentStoreCoordinator(managedObjectModel: model!)
        let storeUrl = contextManager.storeURL()
        
        self.removeStoresBasedOnStoreURL(storeUrl)
        
        let persistentStore = psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: nil, error: nil)

        XCTAssertNotNil(persistentStore, "Store should exist")

        let mocOriginal = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        mocOriginal.persistentStoreCoordinator = psc
        let objectOriginal = NSEntityDescription.insertNewObjectForEntityForName("Theme", inManagedObjectContext: mocOriginal) as NSManagedObject
        mocOriginal.obtainPermanentIDsForObjects([objectOriginal], error: nil)
        var error: NSError?
        mocOriginal.save(&error)

        let objectID = objectOriginal.objectID
        XCTAssertFalse(objectID.temporaryID, "Should be a permanent object")
        psc.removePersistentStore(persistentStore!, error: nil);
    
        let standardPSC = contextManager.standardPSC
    
        XCTAssertNotNil(standardPSC, "New store should exist")
        XCTAssertTrue(standardPSC.persistentStores.count == 1, "Should be one persistent store.")
        
        let mocSecond = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        mocSecond.persistentStoreCoordinator = standardPSC
        let object = mocSecond.existingObjectWithID(objectID, error: nil)
        
        XCTAssertNotNil(object, "Object should exist in new PSC")
    }
    
    func testMigrate21to22() {
        let model21Url = self.urlForModelName("WordPress 21")
        let model22Url = self.urlForModelName("WordPress 22")
        let model = NSManagedObjectModel(contentsOfURL: model21Url!)
        var psc = NSPersistentStoreCoordinator(managedObjectModel: model!)
        let storeUrl = contextManager.storeURL()
        
        self.removeStoresBasedOnStoreURL(storeUrl)
        
        let persistentStore = psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: nil, error: nil)
        
        XCTAssertNotNil(persistentStore, "Store should exist")
        
        let mocOriginal = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        mocOriginal.persistentStoreCoordinator = psc
        let account = NSEntityDescription.insertNewObjectForEntityForName("Account", inManagedObjectContext: mocOriginal) as WPAccount
        account.username = "username"
        account.isWpcom = true
        account.authToken = "authtoken"
        account.xmlrpc = "http://example.com/xmlrpc.php"
        
        mocOriginal.obtainPermanentIDsForObjects([account], error: nil)

        var error: NSError?
        mocOriginal.save(&error)
        
        NSUserDefaults.standardUserDefaults().setURL(account.objectID.URIRepresentation(), forKey: "AccountDefaultDotcom")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        psc.removePersistentStore(persistentStore!, error: nil);
        
        contextManager.managedObjectModel = NSManagedObjectModel(contentsOfURL: model22Url!)
        let standardPSC = contextManager.standardPSC
        
        XCTAssertNotNil(standardPSC, "New store should exist")
        XCTAssertTrue(standardPSC.persistentStores.count == 1, "Should be one persistent store.")
        
        let mocSecond = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        mocSecond.persistentStoreCoordinator = standardPSC
        
        let fetchRequest = NSFetchRequest(entityName: "Account")
        let results = mocSecond.executeFetchRequest(fetchRequest, error: nil)
        
        XCTAssertTrue(results!.count == 1, "Should have one account")
        
        let newAccount = results![0] as WPAccount
        XCTAssertNotNil(newAccount.uuid, "UUID should be assigned")
        XCTAssertTrue(newAccount.username == "username", "Usernames should match")
    }
    
    func urlForModelName(name: NSString!) -> NSURL? {
        var bundle = NSBundle.mainBundle()
        var url = bundle.URLForResource(name, withExtension: "mom")
        
        if (url == nil) {
            var momdPaths = bundle.pathsForResourcesOfType("momd", inDirectory: nil);
            for momdPath in momdPaths {
                url = bundle.URLForResource(name, withExtension: "mom", subdirectory: momdPath.lastPathComponent)
            }
        }
        
        return url
    }
    
    func removeStoresBasedOnStoreURL(storeURL: NSURL) {
        let fileManager = NSFileManager.defaultManager()
        let directoryUrl = storeURL.URLByDeletingLastPathComponent
        let files = fileManager.contentsOfDirectoryAtURL(directoryUrl!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants, error: nil) as Array<NSURL>
        for file in files {
            let range = file.lastPathComponent.rangeOfString(storeURL.lastPathComponent, options: nil, range: nil, locale: nil)
            if range?.startIndex != range?.endIndex {
                fileManager.removeItemAtURL(file, error: nil)
            }
        }
    }
}
