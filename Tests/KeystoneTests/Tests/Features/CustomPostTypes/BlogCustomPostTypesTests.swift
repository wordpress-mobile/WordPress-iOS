import Testing

@testable import WordPress
@testable import WordPressData

@MainActor
struct BlogCustomPostTypesTests {
    @Test("uses Custom Post Types views when XML-RPC is disabled on self-hosted")
    func usesCustomPostTypeViews() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext)
            .isNotHostedAtWPcom()
            .build()
        blog.account = nil
        blog.isXMLRPCDisabled = true

        #expect(blog.usesCustomPostTypeViewsForPostsAndPages)
    }

    @Test("does not use Custom Post Types views when XML-RPC is enabled")
    func doesNotUseCustomPostTypeViewsWithXMLRPC() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        blog.isXMLRPCDisabled = false

        #expect(!blog.usesCustomPostTypeViewsForPostsAndPages)
    }

    @Test("does not use Custom Post Types views for WordPress.com")
    func doesNotUseCustomPostTypeViewsForWordPressCom() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext)
            .isHostedAtWPcom()
            .withAnAccount()
            .build()
        blog.isXMLRPCDisabled = true

        #expect(!blog.usesCustomPostTypeViewsForPostsAndPages)
    }
}
