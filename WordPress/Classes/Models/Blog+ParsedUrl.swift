import Foundation
import WordPressAPI

extension Blog {

    struct SelfHostedLoginDetails {
        let url: URL
        let username: String
        let password: String

        static func fromApplicationPasswordResponse(_ url: URL) throws -> SelfHostedLoginDetails {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let hashMap = components?.queryItems?.reduce(into: [String: String](), { partialResult, item in
                partialResult[item.name] = item.value
            }) else {
                throw BlogCredentialsError.invalidCredentialsUrl
            }

            return try Blog.SelfHostedLoginDetails.from(
                url: hashMap["site_url"],
                username: hashMap["user_login"],
                password: hashMap["password"]
            )
        }

        static func from(url: String?, username: String?, password: String?) throws -> SelfHostedLoginDetails {
            guard let stringUrl = url else {
                throw BlogCredentialsError.blogUrlMissing
            }

            guard let url = URL(string: stringUrl) else {
                throw BlogCredentialsError.blogUrlInvalid
            }

            guard let username = username else {
                throw BlogCredentialsError.blogUsernameMissing
            }

            guard let password = password else {
                throw BlogCredentialsError.blogPasswordMissing
            }

            return SelfHostedLoginDetails(url: url, username: username, password: password)
        }
    }

    enum BlogCredentialsError: Error {
        case blogUrlMissing
        case blogUrlInvalid
        case blogUsernameMissing
        case blogPasswordMissing
        case invalidCredentialsUrl
    }

    func wordPressClientParsedUrl() throws -> ParsedUrl {
        try ParsedUrl.parse(input: self.getUrl().absoluteString)
    }

    func selfHostedCredentials() throws -> SelfHostedLoginDetails {
        return try SelfHostedLoginDetails(
            url: self.getUrl(),
            username: self.getUsername(),
            password: self.getPassword()
        )
    }

    func getApplicationToken() throws {
        try SFHFKeychainUtils.getPasswordForUsername(self.getUsername(), andServiceName: self.getUrl().absoluteString)
    }

    func setApplicationToken(_ newValue: String) throws {
        try SFHFKeychainUtils.storeUsername(
            self.username,
            andPassword: newValue,
            forServiceName: self.url,
            updateExisting: true
        )
    }

    func getUsername() throws -> String {
        guard let username = self.username else {
            throw BlogCredentialsError.blogUsernameMissing
        }

        return username
    }

    func getPassword() throws -> String {
        guard let password = self.password else {
            throw BlogCredentialsError.blogPasswordMissing
        }

        return password
    }

    func setPassword(to newValue: String) throws {
       try SFHFKeychainUtils.storeUsername(
            self.getUsername(),
            andPassword: newValue,
            forServiceName: self.getUrl().absoluteString,
            updateExisting: true
        )
    }

    func getUrl() throws -> URL {
        guard let stringUrl = self.url else {
            throw BlogCredentialsError.blogUrlMissing
        }

        guard let url = URL(string: stringUrl) else {
            throw BlogCredentialsError.blogUrlInvalid
        }

        return url
    }
}
