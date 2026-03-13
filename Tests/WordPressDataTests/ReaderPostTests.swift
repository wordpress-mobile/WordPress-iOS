import CoreData
import Testing
@testable import WordPressData
import WordPressKit
import WordPressKitModels

@MainActor
struct ReaderPostTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    @Test func blogNameForDisplay() {
        let post = mainContext.insertNewObject(ofType: ReaderPost.self)
        post.blogName = "t          r          e          f          o          l          o          g          y"
        #expect(post.blogNameForDisplay() == "t r e f o l o g y")
    }
}
