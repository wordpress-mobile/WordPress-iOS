import Foundation
import Testing
import WordPressData
import WordPressKit

@testable import WordPress

@MainActor
struct TokenlessAccountRemoteFactoryTests {
    private let context = ContextManager.forTesting().mainContext

    // MARK: - Media

    @Test func mediaRemoteForDotComBlogWithTokenUsesREST() throws {
        let blog = RemoteSelectionBlogFixture.dotComBlog(authToken: "token", context: context)
        #expect(try MediaServiceRemoteFactory().remote(for: blog) is MediaServiceRemoteREST)
    }

    @Test func noMediaRemoteForDotComBlogWithoutToken() {
        let blog = RemoteSelectionBlogFixture.dotComBlog(authToken: nil, context: context)
        #expect(throws: MediaRepository.Error.remoteAPIUnavailable) {
            try MediaServiceRemoteFactory().remote(for: blog)
        }
    }

    @Test func mediaRemoteForJetpackBlogWithoutTokenUsesStoredXMLRPCCredentials() throws {
        let blog = RemoteSelectionBlogFixture.jetpackBlog(authToken: nil, xmlrpcPassword: "password", context: context)
        #expect(try MediaServiceRemoteFactory().remote(for: blog) is MediaServiceRemoteXMLRPC)
    }

    @Test func noMediaRemoteForJetpackBlogWithoutTokenOrXMLRPCCredentials() {
        let blog = RemoteSelectionBlogFixture.jetpackBlog(authToken: nil, xmlrpcPassword: nil, context: context)
        #expect(throws: MediaRepository.Error.remoteAPIUnavailable) {
            try MediaServiceRemoteFactory().remote(for: blog)
        }
    }

    // MARK: - Comments

    @Test func commentRemoteForDotComBlogWithTokenUsesREST() {
        let blog = RemoteSelectionBlogFixture.dotComBlog(authToken: "token", context: context)
        #expect(CommentServiceRemoteFactory().remote(blog: blog) is CommentServiceRemoteREST)
    }

    @Test func noCommentRemoteForDotComBlogWithoutToken() {
        let blog = RemoteSelectionBlogFixture.dotComBlog(authToken: nil, context: context)
        #expect(CommentServiceRemoteFactory().remote(blog: blog) == nil)
    }

    @Test func commentRemoteForJetpackBlogWithoutTokenUsesStoredXMLRPCCredentials() {
        let blog = RemoteSelectionBlogFixture.jetpackBlog(authToken: nil, xmlrpcPassword: "password", context: context)
        #expect(CommentServiceRemoteFactory().remote(blog: blog) is CommentServiceRemoteXMLRPC)
    }

    @Test func commentRemoteForSelfHostedBlogIsUnaffected() {
        let blog = RemoteSelectionBlogFixture.selfHostedBlog(context: context)
        #expect(CommentServiceRemoteFactory().remote(blog: blog) is CommentServiceRemoteXMLRPC)
    }
}
