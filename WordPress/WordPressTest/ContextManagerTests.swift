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
        let model19Name = "WordPress 19"
        
        // Instantiate a Model 19 Stack
        startupCoredataStack(model19Name)
        let mocOriginal = contextManager.mainContext
        let psc = contextManager.persistentStoreCoordinator
        
        // Insert a Theme Entity
        let objectOriginal = NSEntityDescription.insertNewObjectForEntityForName("Theme", inManagedObjectContext: mocOriginal) as NSManagedObject
        mocOriginal.obtainPermanentIDsForObjects([objectOriginal], error: nil)
        var error: NSError?
        mocOriginal.save(&error)

        let objectID = objectOriginal.objectID
        XCTAssertFalse(objectID.temporaryID, "Should be a permanent object")

        // Migrate to the latest
        let persistentStore = psc.persistentStores.first as? NSPersistentStore
        psc.removePersistentStore(persistentStore!, error: nil);
    
        let standardPSC = contextManager.standardPSC
    
        XCTAssertNotNil(standardPSC, "New store should exist")
        XCTAssertTrue(standardPSC.persistentStores.count == 1, "Should be one persistent store.")
        
        // Verify if the Theme Entity is there
        let mocSecond = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        mocSecond.persistentStoreCoordinator = standardPSC
        let object = mocSecond.existingObjectWithID(objectID, error: nil)
        
        XCTAssertNotNil(object, "Object should exist in new PSC")
    }
    
    func testMigrate21to22WithoutRunningAccountsFix() {
        let model21Name = "WordPress 21"
        let model22Name = "WordPress 22"
        
        // Instantiate a Model 21 Stack
        startupCoredataStack(model21Name)
        
        let mainContext = contextManager.mainContext
        let psc = contextManager.persistentStoreCoordinator
        
        // Insert a WPAccount entity
        let dotcomAccount = newAccountInContext(mainContext)
        let offsiteAccount = newAccountInContext(mainContext)
        offsiteAccount.isWpcom = false
        offsiteAccount.username = "OffsiteUsername"
        
        mainContext.obtainPermanentIDsForObjects([dotcomAccount, offsiteAccount], error: nil)
        mainContext.save(nil)
        
        // Set the DefaultDotCom
        let dotcomAccountURL = dotcomAccount.objectID.URIRepresentation()
        NSUserDefaults.standardUserDefaults().setURL(dotcomAccountURL, forKey: "AccountDefaultDotcom")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Initialize 21 > 22 Migration
        let secondContext = performCoredataMigration(model22Name)

        // Verify the DefaultAccount
        let fetchRequest = NSFetchRequest(entityName: "Account")
        let results = secondContext.executeFetchRequest(fetchRequest, error: nil) as? [WPAccount]
        XCTAssertTrue(results!.count == 2, "Should have two account")
        
        let defaultAccountUUID = NSUserDefaults.standardUserDefaults().valueForKey("AccountDefaultDotcomUUID") as? String
        var defaultAccount: WPAccount?
        
        for account in results! {
            XCTAssertNotNil(account.uuid, "UUID should be assigned")
            if account.uuid == defaultAccountUUID! {
                defaultAccount = account
            }
        }
        
        XCTAssert(defaultAccount != nil, "Default account not found")
        XCTAssert(defaultAccount!.username == "username", "Invalid Default Account")
    }
    
    func testMigrate21to22RunningAccountsFix() {
        let model21Name = "WordPress 21"
        let model22Name = "WordPress 22"
        
        // Instantiate a Model 21 Stack
        startupCoredataStack(model21Name)
        
        let mainContext = contextManager.mainContext
        let psc = contextManager.persistentStoreCoordinator
        
        // Insert a WordPress.com account with a Jetpack blog
        let wrongAccount = newAccountInContext(mainContext)
        let wrongBlog = newBlogInAccount(wrongAccount)
        wrongAccount.addJetpackBlogsObject(wrongBlog)

        // Insert a WordPress.com account with a Dotcom blog
        let rightAccount = newAccountInContext(mainContext)
        let rightBlog = newBlogInAccount(rightAccount)
        rightAccount.addBlogsObject(rightBlog)
        rightAccount.username = "Right"

        // Insert an offsite WordPress account
        let offsiteAccount = newAccountInContext(mainContext)
        offsiteAccount.isWpcom = false
        
        mainContext.obtainPermanentIDsForObjects([wrongAccount, rightAccount, offsiteAccount], error: nil)
        mainContext.save(nil)
        
        // Set the DefaultDotCom
        let offsiteAccountURL = offsiteAccount.objectID.URIRepresentation()
        NSUserDefaults.standardUserDefaults().setURL(offsiteAccountURL, forKey: "AccountDefaultDotcom")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Initialize 21 > 22 Migration
        let secondContext = performCoredataMigration(model22Name)
        
        // Verify the DefaultAccount
        let fetchRequest = NSFetchRequest(entityName: "Account")
        let results = secondContext.executeFetchRequest(fetchRequest, error: nil)
        
        XCTAssertTrue(results!.count == 3, "Should have three account")

        let defaultAccountUUID = NSUserDefaults.standardUserDefaults().valueForKey("AccountDefaultDotcomUUID") as? String
        var defaultAccount: NSManagedObject?
        
        for account in results! {
            if let uuid = account.valueForKey("uuid") as? String {
                if uuid == defaultAccountUUID {
                    defaultAccount = account as? NSManagedObject
                    break
                }
            }
        }
        let defaultUsername = defaultAccount?.valueForKey("username") as? String
        
        XCTAssert(defaultAccount != nil, "Default account not found")
        XCTAssert(defaultUsername! == "Right", "Invalid default account")
    }
    

    // MARK: - Helper Methods
    
    private func startupCoredataStack(modelName: String) {
        let modelURL = urlForModelName(modelName)
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        
        let storeUrl = contextManager.storeURL()
        removeStoresBasedOnStoreURL(storeUrl)
        
        let persistentStore = persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: nil, error: nil)
        XCTAssertNotNil(persistentStore, "Store should exist")
        
        let mainContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        mainContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        contextManager.managedObjectModel = model
        contextManager.mainContext = mainContext
        contextManager.persistentStoreCoordinator = persistentStoreCoordinator
    }
    
    private func performCoredataMigration(newModelName: String) -> NSManagedObjectContext {
        let psc = contextManager.persistentStoreCoordinator
        let mainContext = contextManager.mainContext
        
        let persistentStore = psc.persistentStores.first as? NSPersistentStore
        psc.removePersistentStore(persistentStore!, error: nil);
        
        let newModelURL = urlForModelName(newModelName)
        contextManager.managedObjectModel = NSManagedObjectModel(contentsOfURL: newModelURL!)
        let standardPSC = contextManager.standardPSC
        
        XCTAssertNotNil(standardPSC, "New store should exist")
        XCTAssertTrue(standardPSC.persistentStores.count == 1, "Should be one persistent store.")
        
        let secondContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        secondContext.persistentStoreCoordinator = standardPSC
        return secondContext
    }
    
    private func urlForModelName(name: NSString!) -> NSURL? {
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
    
    private func removeStoresBasedOnStoreURL(storeURL: NSURL) {
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
    
    private func newAccountInContext(context: NSManagedObjectContext) -> WPAccount {
        let account = NSEntityDescription.insertNewObjectForEntityForName("Account", inManagedObjectContext: context) as WPAccount
        account.username = "username"
        account.isWpcom = true
        account.authToken = "authtoken"
        account.xmlrpc = "http://example.com/xmlrpc.php"
        return account
    }
    
    private func newBlogInAccount(account: WPAccount) -> Blog {
        let blog = NSEntityDescription.insertNewObjectForEntityForName("Blog", inManagedObjectContext: account.managedObjectContext!) as Blog
        blog.xmlrpc = "http://test.blog/xmlrpc.php";
        blog.url = "http://test.blog/";
        blog.account = account
        return blog;
    }
}
