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

    func testIterativeMigration() throws {
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
