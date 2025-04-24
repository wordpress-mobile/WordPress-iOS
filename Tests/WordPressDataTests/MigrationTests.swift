import CoreData
import Testing
@testable import WordPressData

struct MigrationTests {

    // See https://github.com/wordpress-mobile/WordPress-iOS/pull/24494#discussion_r2057152526
    @Test("Verify migration from version 154 (latest version before extraction to framework) to 155 (first version in framework with module modifications) works.")
    func migrate154to155() throws {
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("Migration154to155.sqlite")

        let contextManager154 = ContextManager(
            modelName: "WordPress 154",
            store: storeURL
        )
        let context154 = contextManager154.newDerivedContext()
        let blog = BlogBuilder(context154)
            .build()
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
    }
}
