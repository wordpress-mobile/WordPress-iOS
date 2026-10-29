import CoreData
import Testing
import WordPressKit
@testable import WordPressData

@MainActor
struct BlogTokenlessAccountTests {
    private let contextManager = ContextManager.forTesting()

    private func makeBlog(hostedAtWPCom: Bool, authToken: String?, xmlrpcPassword: String? = nil) -> Blog {
        let blog = BlogBuilder(contextManager.mainContext)
            .with(isHostedAtWPCom: hostedAtWPCom)
            .build()
        let account = WPAccount.fixture(context: contextManager.mainContext)
        account.authToken = authToken
        blog.account = account
        if let xmlrpcPassword {
            blog.username = "xmlrpc-user"
            blog.password = xmlrpcPassword
        }
        return blog
    }

    @Test func dotComBlogWithTokenHasRemote() {
        let blog = makeBlog(hostedAtWPCom: true, authToken: "token")
        #expect(!blog.isMissingRequiredWordPressComToken)
    }

    @Test func dotComBlogWithoutTokenHasNoRemote() {
        #expect(makeBlog(hostedAtWPCom: true, authToken: nil).isMissingRequiredWordPressComToken)
        #expect(makeBlog(hostedAtWPCom: true, authToken: "").isMissingRequiredWordPressComToken)
    }

    @Test func dotComBlogWithoutTokenHasNoRemoteEvenWithXMLRPCPassword() {
        let blog = makeBlog(hostedAtWPCom: true, authToken: nil, xmlrpcPassword: "password")
        #expect(blog.isMissingRequiredWordPressComToken)
    }

    @Test func jetpackBlogWithoutTokenKeepsStoredXMLRPCCredentials() {
        let blog = makeBlog(hostedAtWPCom: false, authToken: nil, xmlrpcPassword: "password")
        #expect(!blog.isMissingRequiredWordPressComToken)
    }

    @Test func jetpackBlogWithoutTokenOrXMLRPCPasswordHasNoRemote() {
        let blog = makeBlog(hostedAtWPCom: false, authToken: nil)
        #expect(blog.isMissingRequiredWordPressComToken)
    }

    @Test func selfHostedBlogIsUnaffected() {
        let blog = BlogBuilder(contextManager.mainContext, dotComID: nil).build()
        blog.account = nil
        #expect(!blog.isMissingRequiredWordPressComToken)
    }

    @Test func noSelfHostedRestApiForDotComBlogWithoutToken() {
        let blog = makeBlog(hostedAtWPCom: true, authToken: nil)
        #expect(WordPressOrgRestApi(blog: blog) == nil)
    }
}
