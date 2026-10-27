import Testing
import SFHFKeychainUtils

/// Ported from the Objective-C `KeychainTest` in KeystoneTests (#24201).
/// These tests exercise the real keychain, so the suite runs serialized.
@Suite(.serialized)
struct KeychainTests {

    private let serviceName = "public-api.wordpress.com"

    init() {
        try? SFHFKeychainUtils.deleteItemForUsername("username", andServiceName: serviceName)
        try? SFHFKeychainUtils.deleteItemForUsername("otherusername", andServiceName: serviceName)
    }

    @Test func noPasswordReturnsNil() throws {
        let password = try SFHFKeychainUtils.getPasswordForUsername("username", andServiceName: serviceName)

        #expect(password == nil)
    }

    @Test func storeAndReadPassword() throws {
        let stored = try SFHFKeychainUtils.storeUsername(
            "username",
            andPassword: "testpasswordreallylong",
            forServiceName: serviceName,
            updateExisting: true
        )
        #expect(stored)

        let password = try SFHFKeychainUtils.getPasswordForUsername("username", andServiceName: serviceName)

        #expect(password != nil)
    }

    /// Regression test for https://github.com/wordpress-mobile/WordPress-iOS/issues/2756
    @Test func changingPasswordDoesNotAffectOtherUsernames() throws {
        try SFHFKeychainUtils.storeUsername(
            "otherusername",
            andPassword: "otherusernamespassword",
            forServiceName: serviceName,
            updateExisting: true
        )
        try SFHFKeychainUtils.storeUsername(
            "username",
            andPassword: "testpasswordreallylong",
            forServiceName: serviceName,
            updateExisting: true
        )
        let updated = try SFHFKeychainUtils.storeUsername(
            "username",
            andPassword: "thisisadifferentpassword",
            forServiceName: serviceName,
            updateExisting: true
        )
        #expect(updated)

        let otherUsernamesPassword = try SFHFKeychainUtils.getPasswordForUsername(
            "otherusername",
            andServiceName: serviceName
        )
        #expect(otherUsernamesPassword == "otherusernamespassword")

        let password = try SFHFKeychainUtils.getPasswordForUsername("username", andServiceName: serviceName)
        #expect(password == "thisisadifferentpassword")
    }
}
