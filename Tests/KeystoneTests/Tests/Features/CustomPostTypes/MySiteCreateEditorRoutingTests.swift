import Testing

@testable import WordPress
@testable import WordPressData

@MainActor
struct MySiteCreateEditorRoutingTests {

    @Test("uses Core REST when XML-RPC is disabled on a self-hosted site")
    func usesCoreRESTForXMLRPCDisabledSelfHostedSite() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        blog.isXMLRPCDisabled = true

        #expect(MySiteViewController.shouldUseCoreRESTEditor(for: blog))
    }

    @Test("uses the existing editor when XML-RPC is enabled on a self-hosted site")
    func usesExistingEditorForXMLRPCEnabledSelfHostedSite() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        blog.isXMLRPCDisabled = false

        #expect(!MySiteViewController.shouldUseCoreRESTEditor(for: blog))
    }

    @Test("uses the existing editor for a WordPress.com site")
    func usesExistingEditorForWordPressComSite() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).isHostedAtWPcom().withAnAccount().build()
        blog.isXMLRPCDisabled = true

        #expect(!MySiteViewController.shouldUseCoreRESTEditor(for: blog))
    }

    @Test("uses the existing editor when there is no selected site")
    func usesExistingEditorWithoutSelectedSite() {
        #expect(!MySiteViewController.shouldUseCoreRESTEditor(for: nil))
    }
}
