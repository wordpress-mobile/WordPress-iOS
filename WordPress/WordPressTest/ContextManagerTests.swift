import CoreData
import Nimble
import XCTest

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

    func testSaveDerivedContextWithChangesInMainContext() throws {
        let contextManager = ContextManager.forTesting()
        let derivedContext = contextManager.newDerivedContext()

        derivedContext.perform {
            _ = WPAccount.fixture(context: derivedContext, userID: 1, username: "First User")
            contextManager.saveContextAndWait(derivedContext)
        }

        let findFirstUser: () throws -> WPAccount? = {
            let firstUserQuery = NSFetchRequest<WPAccount>(entityName: "Account")
            firstUserQuery.predicate = NSPredicate(format: "userID = 1")
            return try contextManager.mainContext.fetch(firstUserQuery).first
        }
        expect(try findFirstUser()?.username).toEventually(equal("First User"))

        // Change first user's user name
        try findFirstUser()?.username = "First User (Updated)"

        // Save another user
        waitUntil { done in
            derivedContext.perform {
                _ = WPAccount.fixture(context: derivedContext, userID: 2)
                contextManager.saveContextAndWait(derivedContext)
                done()
            }
        }

        // Discard the username change that's made above
        contextManager.mainContext.reset()

        expect(try findFirstUser()?.username) == "First User"
    }

    func testSaveUsingBlock() async throws {
        let contextManager = ContextManager.forTesting()
        let numberOfAccounts: () -> Int = {
            contextManager.mainContext.countObjects(ofType: WPAccount.self)
        }
        XCTAssertEqual(numberOfAccounts(), 0)

        try await contextManager.performAndSave { context in
            _ = WPAccount.fixture(context: context, userID: 1)
        }
        XCTAssertEqual(numberOfAccounts(), 1)

        let expectedError = NSError.testInstance()
        do {
            try await contextManager.performAndSave { context in
                _ = WPAccount.fixture(context: context, userID: 100)
                throw expectedError
            }
            XCTFail("The above call should throw")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
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
                _ = WPAccount.fixture(context: context, userID: 2)
            }
        }
        sync()

        XCTAssertEqual(numberOfAccounts(), 2)
    }

    func testSaveUsingBlockWithNestedCalls() {
        let contextManager = ContextManager.forTesting()
        let accounts: () -> Set<String> = {
            let all = (try? contextManager.mainContext.fetch(NSFetchRequest<WPAccount>(entityName: "Account"))) ?? []
            return Set(all.map { $0.username! })
        }
        XCTAssertTrue(accounts().isEmpty)

        let saveOperations = [
            self.expectation(description: "First User is saved"),
            self.expectation(description: "Second User is saved"),
        ]

        contextManager.performAndSave({
            _ = WPAccount.fixture(context: $0, userID: 1, username: "First User")

            contextManager.performAndSave {
                _ = WPAccount.fixture(context: $0, userID: 2, username: "Second User")
            }
            saveOperations[1].fulfill()

            XCTAssertEqual(accounts(), ["Second User"])
        }, completion: {
            saveOperations[0].fulfill()
        }, on: .main)

        wait(for: saveOperations, timeout: 0.1)
        XCTAssertEqual(accounts(), ["First User", "Second User"])
    }

    func testSaveUsingBlockWithNestedCallsUsingAsyncAPI() {
        let contextManager = ContextManager.forTesting()
        let accounts: () -> Set<String> = {
            let all = (try? contextManager.mainContext.fetch(NSFetchRequest<WPAccount>(entityName: "Account"))) ?? []
            return Set(all.map { $0.username! })
        }
        XCTAssertTrue(accounts().isEmpty)

        let saveOperations = [
            self.expectation(description: "First User is saved"),
            self.expectation(description: "Second User is saved"),
        ]

        contextManager.performAndSave({
            _ = WPAccount.fixture(context: $0, userID: 1, username: "First User")

            contextManager.performAndSave({
                _ = WPAccount.fixture(context: $0, userID: 2, username: "Second User")
            }, completion: {
                saveOperations[1].fulfill()
            }, on: .main)
        }, completion: {
            saveOperations[0].fulfill()
        }, on: .main)

        wait(for: saveOperations, timeout: 1)
        XCTAssertEqual(accounts(), ["First User", "Second User"])
    }

    func testConcurrencyAsyncAPI() throws {
        let contextManager = ContextManager.forTesting()

        let iterations = 50
        let username = "AsyncAPI"

        var allCompleted: [XCTestExpectation] = []
        for iter in 1...iterations {
            let expectation = self.expectation(description: "Sync API test iteration \(iter) completed")
            allCompleted.append(expectation)
            contextManager.performAndSave({ context in
                do {
                    try self.createOrUpdateAccount(username: username, newToken: "new-token", in: context)
                } catch {
                    XCTFail("Failed to create/update the account: \(error)")
                }
            }, completion: { expectation.fulfill() }, on: .main)
        }
        wait(for: allCompleted, timeout: 1)

        let request = WPAccount.fetchRequest()
        request.predicate = NSPredicate(format: "username = %@", username)
        try XCTAssertEqual(contextManager.mainContext.count(for: request), 1)
    }

    func testConcurrencyAsyncThrowingAPI() throws {
        let contextManager = ContextManager.forTesting()

        let iterations = 50
        let username = "AsyncAPI"

        var allCompleted: [XCTestExpectation] = []
        for iter in 1...iterations {
            let expectation = self.expectation(description: "Sync API test iteration \(iter) completed")
            allCompleted.append(expectation)
            contextManager.performAndSave({ context in
                try self.createOrUpdateAccount(username: username, newToken: "new-token", in: context)
            }, completion: { _ in expectation.fulfill() }, on: .main)
        }
        wait(for: allCompleted, timeout: 1)

        let request = WPAccount.fetchRequest()
        request.predicate = NSPredicate(format: "username = %@", username)
        try XCTAssertEqual(contextManager.mainContext.count(for: request), 1)
    }

    func testConcurrencySyncAPI() throws {
        let contextManager = ContextManager.forTesting()

        let iterations = 50
        let username = "SyncAPI"

        var allCompleted: [XCTestExpectation] = []
        for iter in 1...iterations {
            let expectation = self.expectation(description: "Sync API test iteration \(iter) completed")
            allCompleted.append(expectation)
            DispatchQueue.global().async {
                contextManager.performAndSave { context in
                    do {
                        try self.createOrUpdateAccount(username: username, newToken: "new-token", in: context)
                    } catch {
                        XCTFail("Failed to create/update the account: \(error)")
                    }
                }
                expectation.fulfill()
            }
        }
        wait(for: allCompleted, timeout: 1)

        let request = WPAccount.fetchRequest()
        request.predicate = NSPredicate(format: "username = %@", username)
        XCTExpectFailure("See the comment in `ContextManager.writerQueue` for details")
        try XCTAssertEqual(contextManager.mainContext.count(for: request), 1)
    }

    /// This test case documents a pitfall in `ContextManager.performAndSave(_:)`, where the
    /// saved changes aren't immediately accessible on the objects in the main context. This
    /// issue doesn't present in `performAndSave(_:completion:on:)`.
    func testUpdateUsingSyncAPI() throws {
        // First, insert an account into the database.
        let contextManager = ContextManager.forTesting()
        contextManager.performAndSave { context in
            _ = WPAccount.fixture(context: context, userID: 1, username: "First User")
        }

        // Fetch the account in the main context
        let account = try WPAccount.lookup(withUserID: 1, in: contextManager.mainContext)
        XCTAssertEqual(account?.username, "First User")

        // Update the account in a background context using the `performAndSave` API, which saves the changes synchronously.
        var theBackgroundContext: NSManagedObjectContext? = nil
        contextManager.performAndSave { context in
            theBackgroundContext = context
            guard let objectID = account?.objectID, let accountInContext = try? context.existingObject(with: objectID) as? WPAccount else {
                XCTFail("Can't find the account")
                return
            }
            accountInContext.username = "Updated"
            XCTAssertEqual(theBackgroundContext?.hasChanges, true)
        }

        XCTAssertEqual(theBackgroundContext?.hasChanges, false, "The background context should be saved when `performAndSave` returns")

        XCTExpectFailure("The account object in the main context doesn't get the updated value immediately")
        XCTAssertEqual(account?.username, "Updated")

        // But eventually (probably in next run loop), it will get the updated value.
        expect(account?.username).toEventually(equal("Updated"))

        // The above issue doesn't present in the async version of `performAndSave` API
        contextManager.performAndSave({ context in
            guard let objectID = account?.objectID, let accountInContext = try? context.existingObject(with: objectID) as? WPAccount else {
                XCTFail("Can't find the account")
                return
            }
            accountInContext.username = "Updated Again"
        }, completion: {
            XCTAssertEqual(account?.username, "Updated Again", "The account object in the main context gets the updated value when the completion block is called")
        }, on: .main)
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

    private func createOrUpdateAccount(username: String, newToken: String, in context: NSManagedObjectContext) throws {
        var account = try WPAccount.lookup(withUsername: username, in: context)
        if account == nil {
            // Will this make tests fail because of the default userID in the fixture?
            account = WPAccount.fixture(context: context, username: username)
        }
        account?.authToken = newToken
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
