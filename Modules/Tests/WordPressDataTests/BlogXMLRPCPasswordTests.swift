import CoreData
import Foundation
import Testing
import WordPressKit

@testable import WordPressData

struct BlogXMLRPCPasswordTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    private func makeSelfHostedBlog() -> Blog {
        let blog = BlogBuilder(mainContext, dotComID: nil)
            .with(username: "admin")
            .build()
        blog.keychain = ServiceKeyedKeychain()
        return blog
    }

    @Test func prefersApplicationPasswordOverAccountPassword() throws {
        let blog = makeSelfHostedBlog()
        try blog.setPassword(to: "account-password", using: blog.keychain)
        try blog.setApplicationToken("app-password", using: blog.keychain)

        #expect(blog.xmlrpcPassword == "app-password")
    }

    @Test func accountPasswordIsUnchangedForWPLogin() throws {
        let blog = makeSelfHostedBlog()
        try blog.setPassword(to: "account-password", using: blog.keychain)
        try blog.setApplicationToken("app-password", using: blog.keychain)

        #expect(blog.password == "account-password")
    }

    @Test func fallsBackToAccountPassword() throws {
        let blog = makeSelfHostedBlog()
        try blog.setPassword(to: "account-password", using: blog.keychain)

        #expect(blog.xmlrpcPassword == "account-password")
    }

    @Test func usesApplicationPasswordWhenItIsTheOnlyOne() throws {
        let blog = makeSelfHostedBlog()
        try blog.setApplicationToken("app-password", using: blog.keychain)

        #expect(blog.xmlrpcPassword == "app-password")
    }

    @Test func isNilWithoutStoredPasswords() {
        let blog = makeSelfHostedBlog()

        #expect(blog.xmlrpcPassword == nil)
    }

    @Test func postRemoteSendsApplicationPassword() throws {
        let blog = makeSelfHostedBlog()
        try blog.setPassword(to: "account-password", using: blog.keychain)
        try blog.setApplicationToken("app-password", using: blog.keychain)

        let remote = try #require(PostServiceRemoteFactory().forBlog(blog) as? PostServiceRemoteXMLRPC)
        let arguments = remote.defaultXMLRPCArguments()

        #expect(arguments.last as? String == "app-password")
    }
}
