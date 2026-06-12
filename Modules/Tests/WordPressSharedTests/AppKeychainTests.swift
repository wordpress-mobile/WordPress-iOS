import Security
import Testing
@testable import WordPressShared

extension KeychainStubSuites {
    @Suite(.serialized)
    struct AppKeychainTests {
        private let privateGroup = "team.private"
        private let sharedGroup = "team.shared"

        private func makeKeychain(sharedGroup: String? = "team.shared") -> AppKeychain {
            AppKeychain(privateGroup: privateGroup, sharedGroup: sharedGroup, keychainUtils: KeychainStub.self)
        }

        init() {
            KeychainStub.reset()
        }

        @Test func readPrefersPrivateGroup() throws {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "private-pw")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "shared-pw")

            let value = try makeKeychain().getPassword(for: "user", serviceName: "svc")
            #expect(value == "private-pw")
        }

        @Test func readFallsBackToSharedGroup() throws {
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "shared-pw")

            let value = try makeKeychain().getPassword(for: "user", serviceName: "svc")
            #expect(value == "shared-pw")
        }

        @Test func readThrowsWhenMissingEverywhere() {
            #expect(throws: (any Error).self) {
                try makeKeychain().getPassword(for: "user", serviceName: "svc")
            }
        }

        @Test func readDoesNotFallBackWithoutSharedGroup() {
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "shared-pw")

            #expect(throws: (any Error).self) {
                try makeKeychain(sharedGroup: nil).getPassword(for: "user", serviceName: "svc")
            }
        }

        @Test func writeTargetsPrivateGroupOnly() throws {
            try makeKeychain().setPassword(for: "user", to: "new-pw", serviceName: "svc")

            #expect(KeychainStub.password(group: privateGroup, service: "svc", username: "user") == "new-pw")
            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "user") == nil)
        }

        @Test func deleteRemovesFromBothGroups() throws {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "pw")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "pw")

            try makeKeychain().setPassword(for: "user", to: nil, serviceName: "svc")

            #expect(KeychainStub.password(group: privateGroup, service: "svc", username: "user") == nil)
            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "user") == nil)
        }

        @Test func deleteSucceedsWhenItemOnlyInSharedGroup() throws {
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "pw")

            try makeKeychain().setPassword(for: "user", to: nil, serviceName: "svc")

            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "user") == nil)
        }

        @Test func deleteRethrowsRealFailures() {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "pw")
            KeychainStub.deleteError = NSError(domain: "KeychainStub", code: Int(errSecInteractionNotAllowed))

            #expect(throws: (any Error).self) {
                try makeKeychain().setPassword(for: "user", to: nil, serviceName: "svc")
            }
        }
    }
}
