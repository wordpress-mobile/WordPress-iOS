import Foundation
import WordPressAPI

extension Blog {

    struct SelfHostedLoginDetails {
        let username: String
        let password: String
    }

    enum BlogCredentialsError: Error {
        case blogUrlMissing
        case blogUsernameMissing
        case blogPasswordMissing
    }

    func wordPressClientParsedUrl() throws -> ParsedUrl {
        try ParsedUrl.parse(input: self.getUrl())
    }

    func selfHostedCredentials() throws -> SelfHostedLoginDetails {
        return try SelfHostedLoginDetails(username: self.getUsername(), password: self.getPassword())
    }

    func getApplicationToken() throws {
        try SFHFKeychainUtils.getPasswordForUsername(self.getUsername(), andServiceName: self.getUrl())
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

    func getUrl() throws -> String {
        guard let url = self.url else {
            throw BlogCredentialsError.blogUrlMissing
        }

        return url
    }
}
