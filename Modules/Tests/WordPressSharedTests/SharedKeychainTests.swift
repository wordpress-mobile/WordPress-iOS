import Testing
@testable import WordPressShared

extension KeychainStubSuites {
    @Suite(.serialized)
    struct SharedKeychainTests {
        private let sharedGroup = "team.shared"

        init() {
            KeychainStub.reset()
        }

        @Test func initFailsWithoutGroup() {
            #expect(SharedKeychain(group: nil, keychainUtils: KeychainStub.self) == nil)
        }

        @Test func readTargetsSharedGroup() throws {
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "pw")
            let keychain = try #require(SharedKeychain(group: sharedGroup, keychainUtils: KeychainStub.self))

            let value = try keychain.getPassword(for: "user", serviceName: "svc")
            #expect(value == "pw")
        }

        @Test func writeTargetsSharedGroup() throws {
            let keychain = try #require(SharedKeychain(group: sharedGroup, keychainUtils: KeychainStub.self))

            try keychain.setPassword(for: "user", to: "pw", serviceName: "svc")
            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "user") == "pw")
        }

        @Test func nilValueDeletesFromSharedGroup() throws {
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "pw")
            let keychain = try #require(SharedKeychain(group: sharedGroup, keychainUtils: KeychainStub.self))

            try keychain.setPassword(for: "user", to: nil, serviceName: "svc")
            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "user") == nil)
        }

        @Test func nilValueSucceedsWhenItemMissing() throws {
            let keychain = try #require(SharedKeychain(group: sharedGroup, keychainUtils: KeychainStub.self))

            try keychain.setPassword(for: "user", to: nil, serviceName: "svc")
            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "user") == nil)
        }
    }
}
