import Security
import Testing
import SFHFKeychainUtils

/// Ported from the Objective-C `KeychainTest` to Swift Testing (#24201).
///
/// These tests exercise the real keychain, so they must run in the app-hosted
/// KeystoneTests bundle (a package test target gets no keychain access — every
/// call fails with `-34018`), and the suite runs serialized.
@Suite(.serialized)
struct KeychainTests {

    private let serviceName = "public-api.wordpress.com"
    private let username = "username"
    private let otherUsername = "otherusername"

    init() {
        // `try?` is intentional: deleting an item that was never stored throws
        // errSecItemNotFound, which is the expected path on a fresh keychain.
        try? SFHFKeychainUtils.deleteItem(forUsername: username, andServiceName: serviceName)
        try? SFHFKeychainUtils.deleteItem(forUsername: otherUsername, andServiceName: serviceName)
    }

    @Test func noPasswordThrows() {
        // `getPassword(forUsername:)` throws when no password is saved; it
        // never returns nil.
        #expect(throws: (any Error).self) {
            try SFHFKeychainUtils.getPassword(forUsername: username, andServiceName: serviceName)
        }
    }

    @Test func storeAndReadPassword() throws {
        // `storeUsername(_:andPassword:forServiceName:updateExisting:)` returns
        // Void and throws on failure, so the `try` itself is the assertion.
        try SFHFKeychainUtils.storeUsername(
            username,
            andPassword: "testpasswordreallylong",
            forServiceName: serviceName,
            updateExisting: true
        )

        let password = try SFHFKeychainUtils.getPassword(forUsername: username, andServiceName: serviceName)

        #expect(password == "testpasswordreallylong")
    }

    /// Regression test for https://github.com/wordpress-mobile/WordPress-iOS/issues/2756
    @Test func changingPasswordDoesNotAffectOtherUsernames() throws {
        try SFHFKeychainUtils.storeUsername(
            otherUsername,
            andPassword: "otherusernamespassword",
            forServiceName: serviceName,
            updateExisting: true
        )
        try SFHFKeychainUtils.storeUsername(
            username,
            andPassword: "testpasswordreallylong",
            forServiceName: serviceName,
            updateExisting: true
        )
        try SFHFKeychainUtils.storeUsername(
            username,
            andPassword: "thisisadifferentpassword",
            forServiceName: serviceName,
            updateExisting: true
        )

        let otherUsernamesPassword = try SFHFKeychainUtils.getPassword(
            forUsername: otherUsername,
            andServiceName: serviceName
        )
        #expect(otherUsernamesPassword == "otherusernamespassword")

        let password = try SFHFKeychainUtils.getPassword(forUsername: username, andServiceName: serviceName)
        #expect(password == "thisisadifferentpassword")
    }
}
