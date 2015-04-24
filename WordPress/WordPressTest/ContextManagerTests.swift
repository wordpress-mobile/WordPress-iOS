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
        let objectOriginal = NSEntityDescription.insertNewObjectForEntityForName("Theme", inManagedObjectContext: mocOriginal) as! NSManagedObject
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
    
    func testMigrate20to21PreservingDefaultAccount() {
        let model20Name = "WordPress 20"
        let model21Name = "WordPress 21"
        
        // Instantiate a Model 20 Stack
        startupCoredataStack(model20Name)
        
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
        let oldRightAccountURL = rightAccount.objectID.URIRepresentation()
        NSUserDefaults.standardUserDefaults().setURL(oldRightAccountURL, forKey: "AccountDefaultDotcom")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Initialize 20 > 21 Migration
        let secondContext = performCoredataMigration(model21Name)
        
        // Verify that the three accounts made it through
        let allAccountsRequest = NSFetchRequest(entityName: "Account")
        let numberOfAccounts = secondContext.countForFetchRequest(allAccountsRequest, error: nil)
        XCTAssertTrue(numberOfAccounts == 3, "Should have three accounts")
        
        // Verify if the Default Account is the right one
        let newRightAccountURL = NSUserDefaults.standardUserDefaults().URLForKey("AccountDefaultDotcom")
        XCTAssert(newRightAccountURL != nil, "Default Account's URL is missing")
        
        let objectID = secondContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(newRightAccountURL!)
        XCTAssert(objectID != nil, "Invalid newRightAccount URL")
        
        let reloadedRightAccount = secondContext.existingObjectWithID(objectID!, error: nil) as? WPAccount
        XCTAssert(reloadedRightAccount != nil, "Couldn't load the right default account")
        XCTAssert(reloadedRightAccount!.username! == "Right", "Invalid default account")
    }
    
    func testMigrate21to23WithoutRunningAccountsFix() {
        let model21Name = "WordPress 21"
        let model23Name = "WordPress 23"
        
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
        
        // Initialize 21 > 23 Migration
        let secondContext = performCoredataMigration(model23Name)

        // Verify that the two accounts have been migrated
        let fetchRequest = NSFetchRequest(entityName: "Account")
        let numberOfAccounts = secondContext.countForFetchRequest(fetchRequest, error: nil)
        XCTAssertTrue(numberOfAccounts == 2, "Should have two account")
        
        // Verify if the Default Account is the right one
        let defaultAccountUUID = NSUserDefaults.standardUserDefaults().stringForKey("AccountDefaultDotcomUUID")
        XCTAssert(defaultAccountUUID != nil, "Missing UUID")
        
        let request = NSFetchRequest(entityName: "Account")
        request.predicate = NSPredicate(format: "uuid == %@", defaultAccountUUID!)
        
        let results = secondContext.executeFetchRequest(request, error: nil) as? [WPAccount]
        XCTAssert(results!.count == 1, "Default account not found")

        let defaultAccount = results!.first!
        XCTAssert(defaultAccount.username == "username", "Invalid Default Account")
    }
    
    func testMigrate21to23RunningAccountsFix() {
        let model21Name = "WordPress 21"
        let model23Name = "WordPress 23"
        
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
        
        // Initialize 21 > 23 Migration
        let secondContext = performCoredataMigration(model23Name)
        
        // Verify that the three accounts made it through
        let allAccountsRequest = NSFetchRequest(entityName: "Account")
        let numberOfAccounts = secondContext.countForFetchRequest(allAccountsRequest, error: nil)
        XCTAssertTrue(numberOfAccounts == 3, "Should have three accounts")

        // Verify if the Default Account is the right one
        let accountUUID = NSUserDefaults.standardUserDefaults().stringForKey("AccountDefaultDotcomUUID")
        XCTAssert(accountUUID != nil, "Default Account's UUID is missing")
        
        let request = NSFetchRequest(entityName: "Account")
        request.predicate = NSPredicate(format: "uuid == %@", accountUUID!)
        
        let results = secondContext.executeFetchRequest(request, error: nil) as? [WPAccount]
        XCTAssert(results != nil, "Default Account has been lost")
        XCTAssert(results?.count == 1, "UUID is not unique!")
        
        let username = results?.first?.username
        XCTAssert(username! == "Right", "Invalid default account")
    }

    func testMigrate24to25AvatarURLtoBasePost() {
        let model24Name = "WordPress 24"
        let model25Name = "WordPress 25"

        // Instantiate a Model 24 Stack
        startupCoredataStack(model24Name)

        let mainContext = contextManager.mainContext
        let psc = contextManager.persistentStoreCoordinator

        let account = newAccountInContext(mainContext)
        let blog = newBlogInAccount(account)

        let authorAvatarURL = "http://lorempixum.com/"

        let post = NSEntityDescription.insertNewObjectForEntityForName("Post", inManagedObjectContext: mainContext) as! Post
        post.blog = blog
        post.authorAvatarURL = authorAvatarURL

        let readerPost = NSEntityDescription.insertNewObjectForEntityForName("ReaderPost", inManagedObjectContext: mainContext) as! ReaderPost
        readerPost.authorAvatarURL = authorAvatarURL

        mainContext.save(nil)

        // Initialize 24 > 25 Migration
        let secondContext = performCoredataMigration(model25Name)

        // Test the existence of Post object after migration
        var error: NSError?
        let allPostsRequest = NSFetchRequest(entityName: "Post")
        let postsResults = secondContext.executeFetchRequest(allPostsRequest, error: &error)
        XCTAssertEqual(1, postsResults!.count, "We should get one Post")

        // Test authorAvatarURL integrity after migration
        let existingPost = postsResults!.first! as! Post
        XCTAssertEqual(existingPost.authorAvatarURL, authorAvatarURL)

        // Test the existence of ReaderPost object after migration
        let allReaderPostsRequest = NSFetchRequest(entityName: "ReaderPost")
        let readerPostsResults = secondContext.executeFetchRequest(allReaderPostsRequest, error: &error)
        XCTAssertEqual(1, readerPostsResults!.count, "We should get one ReaderPost")

        // Test authorAvatarURL integrity after migration
        let existingReaderPost = readerPostsResults!.first! as! ReaderPost
        XCTAssertEqual(existingReaderPost.authorAvatarURL, authorAvatarURL)

        // Test for existence of authorAvatarURL in the model
        let secondAccount = newAccountInContext(secondContext)
        let secondBlog = newBlogInAccount(secondAccount)
        let page = NSEntityDescription.insertNewObjectForEntityForName("Page", inManagedObjectContext: secondContext) as! Page
        page.blog = secondBlog
        page.authorAvatarURL = authorAvatarURL

        error = nil
        secondContext.save(&error)

        XCTAssertNil(error, "Setting authorAvatarURL shouldn't throw an error")
    }

    // MARK: - Helper Methods
    
    private func startupCoredataStack(modelName: String) {
        let modelURL = urlForModelName(modelName)
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        
        let storeUrl = contextManager.storeURL
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
        var url = bundle.URLForResource(name as String, withExtension: "mom")
        
        if url == nil {
            var momdPaths = bundle.pathsForResourcesOfType("momd", inDirectory: nil);
            for momdPath in momdPaths {
                url = bundle.URLForResource(name as String, withExtension: "mom", subdirectory: momdPath.lastPathComponent)
            }
        }
        
        return url
    }
    
    private func removeStoresBasedOnStoreURL(storeURL: NSURL) {
        if storeURL.lastPathComponent == nil {
            return
        }
        
        let fileManager = NSFileManager.defaultManager()
        let directoryUrl = storeURL.URLByDeletingLastPathComponent
        let files = fileManager.contentsOfDirectoryAtURL(directoryUrl!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants, error: nil) as! Array<NSURL>
        for file in files {
            let range = file.lastPathComponent?.rangeOfString(storeURL.lastPathComponent!, options: nil, range: nil, locale: nil)
            if range?.startIndex != range?.endIndex {
                fileManager.removeItemAtURL(file, error: nil)
            }
        }
    }
    
    private func newAccountInContext(context: NSManagedObjectContext) -> WPAccount {
        let account = NSEntityDescription.insertNewObjectForEntityForName("Account", inManagedObjectContext: context) as! WPAccount
        account.username = "username"
        account.isWpcom = true
        account.authToken = "authtoken"
        account.xmlrpc = "http://example.com/xmlrpc.php"
        return account
    }
    
    private func newBlogInAccount(account: WPAccount) -> Blog {
        let blog = NSEntityDescription.insertNewObjectForEntityForName("Blog", inManagedObjectContext: account.managedObjectContext!) as! Blog
        blog.xmlrpc = "http://test.blog/xmlrpc.php";
        blog.url = "http://test.blog/";
        blog.account = account
        return blog;
    }
}
