import CoreData
import Testing
@testable import WordPressData

struct MigrationTests {

    // See https://github.com/wordpress-mobile/WordPress-iOS/pull/24494#discussion_r2057152526
    @Test("Verify migration from version 154 (latest version before extraction to framework) to 155 (first version in framework with module modifications) works.")
    func migrate154to155() throws {
        // Even though we use a temporary directory, the store seems to be reused across test
        // runs—the number of entities increase instead of starting from zero every time.
        // The timestamp suffix avoids the issue.
        //
        // Also, we cannot use the in-memory store, otherwise it gets overridden between
        // ContextManager inits and we cannot check the migration behavior.
        let storeURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Migration154to155-\(Date().timeIntervalSince1970).sqlite")

        let contextManager154 = ContextManager(
            modelName: "WordPress 154",
            store: storeURL
        )
        let context154 = contextManager154.newDerivedContext()
        let blog = BlogBuilder(context154)
            .build()

        // BlogAuthor is one of the Swift-first models that needed module reference updates in
        // https://github.com/wordpress-mobile/WordPress-iOS/pull/24494
        let author = NSEntityDescription.insertNewObject(
            forEntityName: BlogAuthor.entityName(),
            into: context154
        ) as! BlogAuthor

        contextManager154.saveContextAndWait(context154)

        // Create a context manager for the 155 model, it will run the migration automatically
        let contextManager155 = ContextManager(
            modelName: "WordPress 155",
            store: storeURL
        )

        // Check the blog is still there, just to exercise the model...
        let context155 = contextManager155.newDerivedContext()
        let request = Blog.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", blog.url!)
        let results = try context155.fetch(request)
        #expect(results.count == 1)
        #expect((results.first as? Blog)?.url == blog.url)

        let authorRequest = BlogAuthor.fetchRequest()
        authorRequest.predicate = NSPredicate(format: "userID == %@", author.userID)
        let authorResults = try context155.fetch(authorRequest)
        #expect(authorResults.count == 1)
        #expect((authorResults.first as? BlogAuthor)?.userID == author.userID)
    }
}
