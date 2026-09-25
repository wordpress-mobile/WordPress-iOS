import CoreData
import Foundation
import Testing
import WordPressData

@testable import WordPress

/// Covers the `BlogService` bridge that requires the injected `id<CoreDataStack>`
/// to conform to `CoreDataStackSwift` for its background queries.
@Suite(.serialized) @MainActor struct BlogServiceCoreDataStackBridgeTests {

    private let store = ContextManager.forTesting()

    /// Conforms to the base `CoreDataStack` only, so the bridge must reject it
    /// before running any query or network request.
    private final class BaseOnlyCoreDataStack: NSObject, CoreDataStack {
        let mainContext: NSManagedObjectContext

        init(mainContext: NSManagedObjectContext) {
            self.mainContext = mainContext
        }

        func newDerivedContext() -> NSManagedObjectContext { mainContext }
        func saveContextAndWait(_ context: NSManagedObjectContext) {}
        func save(_ context: NSManagedObjectContext) {}
        func save(_ context: NSManagedObjectContext, completion: (() -> Void)?, on queue: DispatchQueue) {}
        func performAndSave(_ block: @escaping (NSManagedObjectContext) -> Void) {}
        func performAndSave(
            _ block: @escaping (NSManagedObjectContext) -> Void,
            completion: (() -> Void)?,
            on queue: DispatchQueue
        ) {}
    }

    /// Builds a `BlogService` whose injected stack conforms only to the base
    /// `CoreDataStack`, so the bridge must reject it. Returns the blog to query.
    private func makeServiceWithUnsupportedStack() -> (BlogService, Blog) {
        let blog = BlogBuilder(store.mainContext).isHostedAtWPcom().build()
        store.saveContextAndWait(store.mainContext)
        let service = BlogService(coreDataStack: BaseOnlyCoreDataStack(mainContext: store.mainContext))
        return (service, blog)
    }

    @Test func syncTaxnomiesFailsForUnsupportedStack() async throws {
        let (service, blog) = makeServiceWithUnsupportedStack()

        await #expect(throws: BlogService.CoreDataStackBridgeError.self) {
            try await service.syncTaxnomies(for: TaggedManagedObjectID(blog))
        }
    }

    @Test func syncPostTypesFailsForUnsupportedStack() async throws {
        let (service, blog) = makeServiceWithUnsupportedStack()

        await #expect(throws: BlogService.CoreDataStackBridgeError.self) {
            try await service.syncPostTypes(for: TaggedManagedObjectID(blog))
        }
    }

    /// A WPCOM Simple blog does not support the Core REST API, so
    /// `CustomPostTypeService(blog:)` returns nil. The supported bridge resolves
    /// the blog from the injected store and returns without network work.
    @Test func syncPostTypesResolvesFromInjectedStoreForSupportedStack() async throws {
        let blog = BlogBuilder(store.mainContext).isHostedAtWPcom().with(atomic: false).build()
        store.saveContextAndWait(store.mainContext)
        let service = BlogService(coreDataStack: store)

        try await service.syncPostTypes(for: TaggedManagedObjectID(blog))
    }
}
