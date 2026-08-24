import Testing
import WordPressData

@testable import WordPress

@MainActor
@Suite("CustomPostTypeService")
struct CustomPostTypeServiceTests {
    @Test("rejects a WordPress.com Simple site")
    func rejectsSimpleSite() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext)
            .with(atomic: false)
            .isHostedAtWPcom()
            .withAnAccount()
            .build()

        #expect(!blog.supportsCoreRESTAPI)
        #expect(CustomPostTypeService(blog: blog) == nil)
    }

    @Test("accepts a WordPress.com Atomic site")
    func acceptsAtomicSite() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext)
            .with(atomic: true)
            .isHostedAtWPcom()
            .withAnAccount()
            .build()

        #expect(blog.supportsCoreRESTAPI)
        #expect(CustomPostTypeService(blog: blog) != nil)
    }
}
