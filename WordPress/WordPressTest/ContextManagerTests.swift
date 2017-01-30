import Foundation
import XCTest
import CoreData

@testable import WordPress

class ContextManagerTests: XCTestCase {
    var contextManager: TestContextManager!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
    }

    override func tearDown() {
        super.tearDown()
        contextManager.mainContext.reset()

        // Note: We'll force TestContextManager override reset, since, for (unknown reasons) the TestContextManager
        // might be retained more than expected, and it may break other core data based tests.
        ContextManager.overrideSharedInstance(nil)
    }

    func testIterativeMigration() {
        let model19Name = "WordPress 19"

        // Instantiate a Model 19 Stack
        startupCoredataStack(model19Name)

        let mocOriginal = contextManager.mainContext
        let psc = contextManager.persistentStoreCoordinator

        // Insert a Theme Entity
        let objectOriginal = NSEntityDescription.insertNewObject(forEntityName: "Theme", into: mocOriginal)
        try! mocOriginal.obtainPermanentIDs(for: [objectOriginal])
        try! mocOriginal.save()

        let objectID = objectOriginal.objectID
        XCTAssertFalse(objectID.isTemporaryID, "Should be a permanent object")

        // Migrate to the latest
        let persistentStore = psc.persistentStores.first!
        try! psc.remove(persistentStore)

        let standardPSC = contextManager.standardPSC

        XCTAssertNotNil(standardPSC, "New store should exist")
        XCTAssertTrue(standardPSC.persistentStores.count == 1, "Should be one persistent store.")

        // Verify if the Theme Entity is there
        let mocSecond = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        mocSecond.persistentStoreCoordinator = standardPSC
        let object = try! mocSecond.existingObject(with: objectID)

        XCTAssertNotNil(object, "Object should exist in new PSC")
    }

    func testMigrate20to21PreservingDefaultAccount() {
        let model20Name = "WordPress 20"
        let model21Name = "WordPress 21"

        // Instantiate a Model 20 Stack
        startupCoredataStack(model20Name)

        let mainContext = contextManager.mainContext
        _ = contextManager.persistentStoreCoordinator

        // Insert a WordPress.com account with a Jetpack blog
        let wrongAccount = newAccountInContext(context: mainContext)
        let wrongBlog = newBlogInAccount(account: wrongAccount)
        wrongAccount.addJetpackBlogsObject(wrongBlog)

        // Insert a WordPress.com account with a Dotcom blog
        let rightAccount = newAccountInContext(context: mainContext)
        let rightBlog = newBlogInAccount(account: rightAccount)
        rightAccount.addBlogsObject(rightBlog)
        rightAccount.username = "Right"

        // Insert an offsite WordPress account
        let offsiteAccount = newAccountInContext(context: mainContext)
        offsiteAccount.setValue(false, forKey: "isWpcom")

        try! mainContext.obtainPermanentIDs(for: [wrongAccount, rightAccount, offsiteAccount])
        try! mainContext.save()

        // Set the DefaultDotCom
        let oldRightAccountURL = rightAccount.objectID.uriRepresentation()
        UserDefaults.standard.set(oldRightAccountURL, forKey: "AccountDefaultDotcom")
        UserDefaults.standard.synchronize()

        // Initialize 20 > 21 Migration
        let secondContext = performCoredataMigration(model21Name)

        // Verify that the three accounts made it through
        let allAccountsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        let numberOfAccounts = try! secondContext.count(for: allAccountsRequest)
        XCTAssertTrue(numberOfAccounts == 3, "Should have three accounts")

        // Verify if the Default Account is the right one
        let newRightAccountURL = UserDefaults.standard.url(forKey: "AccountDefaultDotcom")
        XCTAssert(newRightAccountURL != nil, "Default Account's URL is missing")

        let objectID = secondContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: newRightAccountURL!)
        XCTAssert(objectID != nil, "Invalid newRightAccount URL")

        let reloadedRightAccount = try! secondContext.existingObject(with: objectID!) as? WPAccount
        XCTAssert(reloadedRightAccount != nil, "Couldn't load the right default account")
        XCTAssert(reloadedRightAccount!.username! == "Right", "Invalid default account")
    }

    func testMigrate21to23WithoutRunningAccountsFix() {
        let model21Name = "WordPress 21"
        let model23Name = "WordPress 23"

        // Instantiate a Model 21 Stack
        startupCoredataStack(model21Name)

        let mainContext = contextManager.mainContext
        _ = contextManager.persistentStoreCoordinator

        // Insert a WPAccount entity
        let dotcomAccount = newAccountInContext(context: mainContext)
        let offsiteAccount = newAccountInContext(context: mainContext)
        offsiteAccount.setValue(false, forKey: "isWpcom")
        offsiteAccount.username = "OffsiteUsername"

        try! mainContext.obtainPermanentIDs(for: [dotcomAccount, offsiteAccount])
        try! mainContext.save()

        // Set the DefaultDotCom
        let dotcomAccountURL = dotcomAccount.objectID.uriRepresentation()
        UserDefaults.standard.set(dotcomAccountURL, forKey: "AccountDefaultDotcom")
        UserDefaults.standard.synchronize()

        // Initialize 21 > 23 Migration
        let secondContext = performCoredataMigration(model23Name)

        // Verify that the two accounts have been migrated
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        let numberOfAccounts = try! secondContext.count(for: fetchRequest)
        XCTAssertTrue(numberOfAccounts == 2, "Should have two account")

        // Verify if the Default Account is the right one
        let defaultAccountUUID = UserDefaults.standard.string(forKey: "AccountDefaultDotcomUUID")
        XCTAssert(defaultAccountUUID != nil, "Missing UUID")

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        request.predicate = NSPredicate(format: "uuid == %@", defaultAccountUUID!)

        let results = try! secondContext.fetch(request) as? [WPAccount]
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
        _ = contextManager.persistentStoreCoordinator

        // Insert a WordPress.com account with a Jetpack blog
        let wrongAccount = newAccountInContext(context: mainContext)
        let wrongBlog = newBlogInAccount(account: wrongAccount)
        wrongAccount.addJetpackBlogsObject(wrongBlog)

        // Insert a WordPress.com account with a Dotcom blog
        let rightAccount = newAccountInContext(context: mainContext)
        let rightBlog = newBlogInAccount(account: rightAccount)
        rightAccount.addBlogsObject(rightBlog)
        rightAccount.username = "Right"

        // Insert an offsite WordPress account
        let offsiteAccount = newAccountInContext(context: mainContext)
        offsiteAccount.setValue(false, forKey: "isWpcom")

        try! mainContext.obtainPermanentIDs(for: [wrongAccount, rightAccount, offsiteAccount])
        try! mainContext.save()

        // Set the DefaultDotCom
        let offsiteAccountURL = offsiteAccount.objectID.uriRepresentation()
        UserDefaults.standard.set(offsiteAccountURL, forKey: "AccountDefaultDotcom")
        UserDefaults.standard.synchronize()

        // Initialize 21 > 23 Migration
        let secondContext = performCoredataMigration(model23Name)

        // Verify that the three accounts made it through
        let allAccountsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        let numberOfAccounts = try! secondContext.count(for: allAccountsRequest)
        XCTAssertTrue(numberOfAccounts == 3, "Should have three accounts")

        // Verify if the Default Account is the right one
        let accountUUID = UserDefaults.standard.string(forKey: "AccountDefaultDotcomUUID")
        XCTAssert(accountUUID != nil, "Default Account's UUID is missing")

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        request.predicate = NSPredicate(format: "uuid == %@", accountUUID!)

        let results = try! secondContext.fetch(request) as? [WPAccount]
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
        _ = contextManager.persistentStoreCoordinator

        let account = newAccountInContext(context: mainContext)
        let blog = newBlogInAccount(account: account)

        let authorAvatarURL = "http://lorempixum.com/"

        let post = NSEntityDescription.insertNewObject(forEntityName: "Post", into: mainContext) as! Post
        post.blog = blog
        post.authorAvatarURL = authorAvatarURL

        let readerPost = NSEntityDescription.insertNewObject(forEntityName: "ReaderPost", into: mainContext) as! ReaderPost
        readerPost.authorAvatarURL = authorAvatarURL

        try! mainContext.save()

        // Initialize 24 > 25 Migration
        let secondContext = performCoredataMigration(model25Name)

        // Test the existence of Post object after migration
        let allPostsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
        let postsResults = try! secondContext.fetch(allPostsRequest)
        XCTAssertEqual(1, postsResults.count, "We should get one Post")

        // Test authorAvatarURL integrity after migration
        let existingPost = postsResults.first! as! Post
        XCTAssertEqual(existingPost.authorAvatarURL, authorAvatarURL)

        // Test the existence of ReaderPost object after migration
        let allReaderPostsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderPost")
        let readerPostsResults = try! secondContext.fetch(allReaderPostsRequest)
        XCTAssertEqual(1, readerPostsResults.count, "We should get one ReaderPost")

        // Test authorAvatarURL integrity after migration
        let existingReaderPost = readerPostsResults.first! as! ReaderPost
        XCTAssertEqual(existingReaderPost.authorAvatarURL, authorAvatarURL)

        // Test for existence of authorAvatarURL in the model
        let secondAccount = newAccountInContext(context: secondContext)
        let secondBlog = newBlogInAccount(account: secondAccount)
        let page = NSEntityDescription.insertNewObject(forEntityName: String(describing: Page.self), into: secondContext) as! Page
        page.blog = secondBlog
        page.authorAvatarURL = authorAvatarURL

        do {
            try secondContext.save()
        } catch let error as NSError {
            XCTAssertNil(error, "Setting authorAvatarURL shouldn't throw an error")
        }
    }

    // MARK: - Helper Methods

    fileprivate func startupCoredataStack(_ modelName: String) {
        let modelURL = urlForModelName(modelName)!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        let storeUrl = contextManager.storeURL
        removeStoresBasedOnStoreURL(storeUrl)
        do {
            _ = try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: nil)
        } catch let error as NSError {
            XCTAssertNil(error, "Store should exist")
        }

        let mainContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        mainContext.persistentStoreCoordinator = persistentStoreCoordinator

        contextManager.managedObjectModel = model
        contextManager.mainContext = mainContext
        contextManager.persistentStoreCoordinator = persistentStoreCoordinator
    }

    fileprivate func performCoredataMigration(_ newModelName: String) -> NSManagedObjectContext {
        let psc = contextManager.persistentStoreCoordinator
        _ = contextManager.mainContext

        let persistentStore = psc.persistentStores.first!
        try! psc.remove(persistentStore)

        let newModelURL = urlForModelName(newModelName)!
        contextManager.managedObjectModel = NSManagedObjectModel(contentsOf: newModelURL)!
        let standardPSC = contextManager.standardPSC

        XCTAssertNotNil(standardPSC, "New store should exist")
        XCTAssertTrue(standardPSC.persistentStores.count == 1, "Should be one persistent store.")

        let secondContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        secondContext.persistentStoreCoordinator = standardPSC
        return secondContext
    }

    fileprivate func urlForModelName(_ name: String) -> URL? {
        let bundle = Bundle.main
        var url = bundle.url(forResource: name, withExtension: "mom")

        if url == nil {
            let momdPaths = bundle.urls(forResourcesWithExtension: "momd", subdirectory: nil)!
            for momdPath in momdPaths {
                url = bundle.url(forResource: name, withExtension: "mom", subdirectory: momdPath.lastPathComponent)
            }
        }

        return url
    }

    fileprivate func removeStoresBasedOnStoreURL(_ storeURL: URL) {
        if storeURL.lastPathComponent.isEmpty {
            return
        }

        let fileManager = FileManager.default
        let directoryUrl = storeURL.deletingLastPathComponent
        let files = try! fileManager.contentsOfDirectory(at: directoryUrl(), includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants)
        for file in files {
            let range = file.lastPathComponent.range(of: storeURL.lastPathComponent)
            if range?.lowerBound != range?.upperBound {
                try! fileManager.removeItem(at: file)
            }
        }
    }

    private func newAccountInContext(context: NSManagedObjectContext) -> WPAccount {
        let account = NSEntityDescription.insertNewObject(forEntityName: "Account", into: context) as! WPAccount
        account.username = "username"
        account.setValue(true, forKey: "isWpcom")
        account.authToken = "authtoken"
        account.setValue("http://example.com/xmlrpc.php", forKey: "xmlrpc")
        return account
    }

    private func newBlogInAccount(account: WPAccount) -> Blog {
        let blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: account.managedObjectContext!) as! Blog
        blog.xmlrpc = "http://test.blog/xmlrpc.php"
        blog.url = "http://test.blog/"
        blog.account = account
        return blog
    }
}
