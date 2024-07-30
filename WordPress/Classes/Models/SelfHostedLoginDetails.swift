import Foundation
import CryptoKit

// TODO: The majority of this should probably be cross-platform code
struct SelfHostedLoginDetails {
    let url: URL
    let username: String
    let password: String
    let xmlrpcEndpoint: URL?

    var derivedXMLRPCRoot: URL {
        url.appendingPathComponent("/xmlrpc.php")
    }

    var derivedSiteId: String {
        SHA256.hash(data: Data(url.absoluteString.localizedLowercase.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    static func fromApplicationPasswordResponse(_ url: URL) throws -> SelfHostedLoginDetails {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let hashMap = components?.queryItems?.reduce(into: [String: String](), { partialResult, item in
            partialResult[item.name] = item.value
        }) else {
            throw Blog.BlogCredentialsError.invalidCredentialsUrl
        }

        guard let stringUrl = hashMap["site_url"] else {
            throw Blog.BlogCredentialsError.blogUrlMissing
        }

        guard let url = URL(string: stringUrl) else {
            throw Blog.BlogCredentialsError.blogUrlInvalid
        }

        guard let username = hashMap["user_login"] else {
            throw Blog.BlogCredentialsError.blogUsernameMissing
        }

        guard let password = hashMap["password"] else {
            throw Blog.BlogCredentialsError.blogPasswordMissing
        }

        return SelfHostedLoginDetails(url: url, username: username, password: password, xmlrpcEndpoint: nil)
    }

    static func from(blog: Blog) throws -> SelfHostedLoginDetails {
        return try SelfHostedLoginDetails(
            url: blog.getUrl(),
            username: blog.getUsername(),
            password: blog.getPassword(),
            xmlrpcEndpoint: try? blog.getXMLRPCEndpoint() // We're ok with this failing because it may not be needed
        )
    }
}
