import Foundation
import XCTest
import CoreData

@testable import WordPress

class ContextManagerTests: XCTestCase {
    let storeURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ContextManagerTests.sqlite")

    override func setUpWithError() throws {
        if FileManager.default.fileExistsAtURL(storeURL) {
            try FileManager.default.removeItem(at: storeURL)
        }
    }

    func testIterativeMigration130ToLatest() throws {
        var objectID: NSManagedObjectID? = .none

        // At the time of writing we are at app version 19.9 and model version 140.
        // At app version 19.0 we were at model version 137.
        // Iterating back 10 version is more than plenty to cover a real world scenario.
        try prepareForMigration(withModelName: "WordPress 130") { context in
            // Add an object to the DB from a model that looks different between the intial and the
            // latest scheme version, so that we fully exercise the migration.
            let originalObject = NSEntityDescription.insertNewObject(
                forEntityName: "Comment",
                into: context
            )
            try context.obtainPermanentIDs(for: [originalObject])
            try context.save()

            XCTAssertFalse(originalObject.objectID.isTemporaryID, "Should be a permanent object")
            objectID = originalObject.objectID

            try XCTAssertThrowsError(
                WPException.objcTry({
                    originalObject.value(forKey: "authorID")
                }),
                "Blog.organizationID doesn't exist in WordPress 130 but we were able to fetch it"
            )
        }

        // Migrate to the latest version
        let contextManager = ContextManager(modelName: ContextManagerModelNameCurrent, store: storeURL)

        let object = try contextManager.mainContext.existingObject(with: XCTUnwrap(objectID))
        XCTAssertNotNil(object, "Object should exist in new PSC")
        XCTAssertNoThrow(
            object.value(forKey: "authorID"),
            "Blog.organizationID exists in latest model version, but we were unable to fetch it"
        )
    }

    // The `_` at the start of the method makes it so that the XCTest runner will not pick it up as
    // a test to run.
    //
    // It's not practical to run this test every time because it walks through 100+ migrations and
    // takes 90 seconds (Intel MacBook Pro 2019)!
    //
    // We're keeping the code here just in case we'll ever need to test the full migration flow.
    func _testIterativeMigration19ToLatest() throws {
        var objectID: NSManagedObjectID? = nil

        try prepareForMigration(withModelName: "WordPress 19") { context in
            // Insert a Theme Entity
            let objectOriginal = NSEntityDescription.insertNewObject(forEntityName: "Theme", into: context)
            try context.obtainPermanentIDs(for: [objectOriginal])
            try context.save()

            XCTAssertFalse(objectOriginal.objectID.isTemporaryID, "Should be a permanent object")
            objectID = objectOriginal.objectID

            try XCTAssertThrowsError(
                WPException.objcTry({
                    objectOriginal.value(forKey: "author")
                }),
                "Theme.author doesn't exist in WordPress 19 but we were able to fetch it"
            )
        }

        // Migrate to the latest
        let contextManager = ContextManager(modelName: ContextManagerModelNameCurrent, store: storeURL)
        let object = try contextManager.mainContext.existingObject(with: XCTUnwrap(objectID))
        XCTAssertNotNil(object, "Object should exist in new PSC")
        XCTAssertNoThrow(object.value(forKey: "author"), "Theme.author should exist in current model version, but we were unable to fetch it")
    }

    func testMigrate24to25AvatarURLtoBasePost() throws {
        let model24Name = "WordPress 24"
        let model25Name = "WordPress 25"

        let authorAvatarURL = "http://lorempixum.com/"

        try prepareForMigration(withModelName: model24Name) { context in
            let account = newAccountInContext(context: context)
            let blog = newBlogInAccount(account: account)

            let post = NSEntityDescription.insertNewObject(forEntityName: "Post", into: context) as! Post
            post.blog = blog
            post.authorAvatarURL = authorAvatarURL

            let readerPost = NSEntityDescription.insertNewObject(forEntityName: "ReaderPost", into: context) as! ReaderPost
            readerPost.authorAvatarURL = authorAvatarURL

            try context.save()
        }

        // Initialize 24 > 25 Migration
        let contextManager = ContextManager(modelName: model25Name, store: storeURL)
        let secondContext = contextManager.mainContext

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

    func testSaveUsingBlock() async {
        let contextManager = ContextManagerMock()
        let numberOfAccounts: () -> Int = {
            contextManager.mainContext.countObjects(ofType: WPAccount.self)
        }
        XCTAssertEqual(numberOfAccounts(), 0)

        await contextManager.performAndSave { context in
            let account = WPAccount(context: context)
            account.userID = 1
            account.username = "First User"
        }
        XCTAssertEqual(numberOfAccounts(), 1)

        // In the translated Swift API of `ContextManager`, there are two `save(_: (NSManagedContext) -> Void)`
        // functions. The only difference between them is, one is async function, the other is not.
        // When compiling statement `try save { context in doSomething(context) }`, Swift picks which overload to use
        // based on the context—there is no syntax or keyword to explicitly pick one ourselves.
        //
        // From: https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md#overloading-and-overload-resolution
        // > "In non-async functions, and closures without any await expression, the compiler selects the non-async overload"
        let sync: () -> Void = {
            contextManager.performAndSave { context in
                let account = WPAccount(context: context)
                account.userID = 2
                account.username = "Second User"
            }
        }
        sync()

        XCTAssertEqual(numberOfAccounts(), 2)
    }

    func testSaveUsingBlockWithNestedCalls() {
        let contextManager = ContextManagerMock()
        let accounts: () -> Set<String> = {
            let all = (try? contextManager.mainContext.fetch(NSFetchRequest<WPAccount>(entityName: "Account"))) ?? []
            return Set(all.map { $0.username! })
        }
        XCTAssertTrue(accounts().isEmpty)

        let saveOperations = [
            self.expectation(description: "First User is saved"),
            self.expectation(description: "Second User is saved"),
        ]

        contextManager.performAndSave {
            let account = WPAccount(context: $0)
            account.userID = 1
            account.username = "First User"

            contextManager.performAndSave {
                let account = WPAccount(context: $0)
                account.userID = 2
                account.username = "Second User"
            }
            saveOperations[1].fulfill()

            XCTAssertEqual(accounts(), ["Second User"])
        } completion: {
            saveOperations[0].fulfill()
        }

        wait(for: saveOperations, timeout: 0.1)
        XCTAssertEqual(accounts(), ["First User", "Second User"])
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

    /// Insert data into `storeURL` using the context object provided by this function.
    ///
    /// This function ensures created Core Data stack is cleaned up properly, so that the database file
    /// is ready to be used by `ContextManager` to perform migration.
    private func prepareForMigration(withModelName modelName: String, block: (NSManagedObjectContext) throws -> Void) throws {
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: XCTUnwrap(urlForModelName(modelName))))
        let container = NSPersistentContainer(name: "WordPress", managedObjectModel: model)
        let storeDesc = NSPersistentStoreDescription(url: storeURL)
        storeDesc.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [storeDesc]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        try block(container.viewContext)

        let store = try XCTUnwrap(container.persistentStoreCoordinator.persistentStores.first)
        try container.persistentStoreCoordinator.remove(store)
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
}
