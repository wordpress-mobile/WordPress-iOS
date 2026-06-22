import Testing
import CoreData

@testable import WordPressData

struct CoreDataMigrationTests {

    @Test func modelURL() {
        let url = urlForModel(name: "WordPress 102")
        #expect(url != nil)
    }

    /// In model 104, we updated transformables to use the NSSecureUnarchiveFromData transformer type.
    /// Here we'll check that they're still accessible after a migration.
    @Test func migrationFrom103To104Transformables() throws {
        let model103Url = try #require(urlForModel(name: "WordPress 103"))
        let model104Url = try #require(urlForModel(name: "WordPress 104"))
        let storeUrl = storeURL(named: "WordPress103.sqlite")

        // Load a Model 103 Stack
        let model103 = try #require(NSManagedObjectModel(contentsOf: model103Url))
        var psc: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: model103)

        let options: [String: Any] = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true
        ]

        let ps = try psc?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
        #expect(ps != nil)

        var context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = psc

        // Create a dictionary-backed transformable
        let blog1ID = NSNumber(value: 987)
        let blog1 = insertDummyBlog(in: context, blogID: blog1ID)
        let blogOptions: NSDictionary = [
            "allowed_file_types": ["pdf", "xls", "jpg"]
        ]
        blog1.setValue(blogOptions, forKey: "options")

        // Create an array-backed transformable
        let post1 = insertDummyPost(in: context, blog: blog1)
        let revisions: NSArray = [NSNumber(value: 123), NSNumber(value: 124)]
        post1.setValue(revisions, forKey: "revisions")

        try context.save()

        psc = nil

        // Migrate to Model 104
        let model104 = try #require(NSManagedObjectModel(contentsOf: model104Url))
        try CoreDataIterativeMigrator.iterativeMigrate(
            sourceStore: storeUrl,
            storeType: NSSQLiteStoreType,
            to: model104,
            using: ["WordPress 103", "WordPress 104"]
        )

        // Load a Model 104 Stack
        psc = NSPersistentStoreCoordinator(managedObjectModel: model104)
        _ = try psc?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)

        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = psc

        // Check that our properties persisted
        let fetchedBlog1 = try fetchFirst("Blog", predicate: "blogID = %i", arguments: [blog1ID], in: context)
        try #require(fetchedBlog1 != nil)

        let blog1Posts = fetchedBlog1?.value(forKey: "posts") as? NSSet
        #expect(blog1Posts?.count == 1)

        let fetchedOptions = fetchedBlog1?.value(forKey: "options") as? NSDictionary
        #expect(fetchedOptions == blogOptions)

        let fetchedPost1 = blog1Posts?.anyObject() as? NSManagedObject
        let fetchedRevisions = fetchedPost1?.value(forKey: "revisions") as? NSArray
        #expect(fetchedRevisions == revisions)
    }

    /// In model 104, we updated some transformables to use custom Transformer subclasses.
    /// Here we'll check that they're still accessible after a migration.
    @Test func migrationFrom103To104CustomTransformers() throws {
        let model103Url = try #require(urlForModel(name: "WordPress 103"))
        let model104Url = try #require(urlForModel(name: "WordPress 104"))
        let storeUrl = storeURL(named: "WordPress103-1.sqlite")

        // Load a Model 103 Stack
        let model103 = try #require(NSManagedObjectModel(contentsOf: model103Url))
        var psc: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: model103)

        let options: [String: Any] = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true
        ]

        let ps = try psc?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
        #expect(ps != nil)

        var context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = psc

        let blog1 = insertDummyBlog(in: context, blogID: NSNumber(value: 123))

        // BlogSettings uses Set transformers
        let settings1 = NSEntityDescription.insertNewObject(forEntityName: "BlogSettings", into: context)
        let moderationKeys = NSSet(array: ["purple", "monkey", "dishwasher"])
        settings1.setValue(moderationKeys, forKey: "commentsModerationKeys")
        blog1.setValue(settings1, forKey: "settings")

        // Media has an Error transformer
        let media1 = NSEntityDescription.insertNewObject(forEntityName: "Media", into: context)
        media1.setValue(blog1, forKey: "blog")
        // The UserInfo dictionary of an NSError can contain types that can't be securely coded,
        // which will throw a Core Data exception on save. We attach an NSUnderlyingError with the
        // expectation that it won't be included when the error is encoded and persisted.
        let underlyingError = NSError(domain: NSURLErrorDomain, code: 500, userInfo: nil)
        let error1 = NSError(domain: NSURLErrorDomain, code: 100, userInfo: [
            NSLocalizedDescriptionKey: "test",
            NSUnderlyingErrorKey: underlyingError
        ])
        media1.setValue(error1, forKey: "error")

        try context.save()

        psc = nil

        // Migrate to Model 104
        let model104 = try #require(NSManagedObjectModel(contentsOf: model104Url))
        try CoreDataIterativeMigrator.iterativeMigrate(
            sourceStore: storeUrl,
            storeType: NSSQLiteStoreType,
            to: model104,
            using: ["WordPress 103", "WordPress 104"]
        )

        // Load a Model 104 Stack
        psc = NSPersistentStoreCoordinator(managedObjectModel: model104)
        _ = try psc?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)

        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = psc

        // Check that our properties persisted
        let fetchedMedia1 = try fetchFirst("Media", in: context)
        // The expected error is stripped of any keys not included in the Media.error setter
        let expectedError = NSError(domain: NSURLErrorDomain, code: 100, userInfo: [NSLocalizedDescriptionKey: "test"])
        #expect(fetchedMedia1?.value(forKey: "error") as? NSError == expectedError)

        let fetchedBlog1 = try fetchFirst("Blog", predicate: "blogID = %i", arguments: [NSNumber(value: 123)], in: context)
        try #require(fetchedBlog1 != nil)

        let fetchedSettings = fetchedBlog1?.value(forKey: "settings") as? NSManagedObject
        let fetchedKeys = fetchedSettings?.value(forKey: "commentsModerationKeys") as? NSSet
        #expect(fetchedKeys == moderationKeys)
    }

    // MARK: - Helpers

    private func urlForModel(name: String) -> URL? {
        let bundle = Bundle.wordPressData
        var url = bundle.url(forResource: name, withExtension: "mom")

        if url == nil {
            let momdPaths = bundle.paths(forResourcesOfType: "momd", inDirectory: nil)
            for momdPath in momdPaths {
                url = bundle.url(
                    forResource: name,
                    withExtension: "mom",
                    subdirectory: URL(fileURLWithPath: momdPath).lastPathComponent
                )
                if url != nil { break }
            }
        }

        return url
    }

    private func storeURL(named fileName: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        return url
    }

    private func insertDummyBlog(in context: NSManagedObjectContext, blogID: NSNumber) -> NSManagedObject {
        let blog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: context)
        blog.setValue(blogID, forKey: "blogID")
        blog.setValue("https://example.com", forKey: "url")
        blog.setValue("https://example.com/xmlrpc.php", forKey: "xmlrpc")
        return blog
    }

    private func insertDummyPost(in context: NSManagedObjectContext, blog: NSManagedObject) -> NSManagedObject {
        let post = NSEntityDescription.insertNewObject(forEntityName: "Post", into: context)
        post.setValue(blog, forKey: "blog")
        return post
    }

    private func fetchFirst(
        _ entityName: String,
        predicate: String? = nil,
        arguments: [Any]? = nil,
        in context: NSManagedObjectContext
    ) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        if let predicate {
            request.predicate = NSPredicate(format: predicate, argumentArray: arguments)
        }
        return try context.fetch(request).first
    }
}
