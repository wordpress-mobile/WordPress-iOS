import Foundation
import Security
import Testing
import WordPressShared

/// Runs against the simulator's real keychain, through the test host's entitlements.
struct SynchronizableAppKeychainIntegrationTests {
    private let service = "SynchronizableAppKeychainIntegrationTests.\(UUID().uuidString)"
    private let username = "user"

    @Test func savesItemsForICloudKeychainSync() throws {
        let keychain = AppKeychain().synchronizable
        defer { try? keychain.setPassword(for: username, to: nil, serviceName: service) }

        try keychain.setPassword(for: username, to: "secret", serviceName: service)

        #expect(try keychain.getPassword(for: username, serviceName: service) == "secret")
        #expect(itemExists(synchronizable: true))
        #expect(!itemExists(synchronizable: false))
    }

    @Test func updatesAnExistingItem() throws {
        let keychain = AppKeychain().synchronizable
        defer { try? keychain.setPassword(for: username, to: nil, serviceName: service) }

        try keychain.setPassword(for: username, to: "old", serviceName: service)
        try keychain.setPassword(for: username, to: "new", serviceName: service)

        #expect(try keychain.getPassword(for: username, serviceName: service) == "new")
    }

    @Test func movesItemsSavedOnThisDeviceOnlyIntoTheSyncedStore() throws {
        let keychain = AppKeychain().synchronizable
        defer { try? keychain.setPassword(for: username, to: nil, serviceName: service) }
        try AppKeychain().setPassword(for: username, to: "secret", serviceName: service)
        #expect(itemExists(synchronizable: false))

        #expect(try keychain.getPassword(for: username, serviceName: service) == "secret")
        #expect(itemExists(synchronizable: true))
        #expect(!itemExists(synchronizable: false))
    }

    @Test func deleteRemovesBothCopies() throws {
        let keychain = AppKeychain().synchronizable
        try keychain.setPassword(for: username, to: "secret", serviceName: service)

        try keychain.setPassword(for: username, to: nil, serviceName: service)

        #expect(!itemExists(synchronizable: true))
        #expect(!itemExists(synchronizable: false))
        #expect(throws: (any Error).self) {
            try keychain.getPassword(for: username, serviceName: service)
        }
    }

    private func itemExists(synchronizable: Bool) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecAttrSynchronizable as String: synchronizable
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
}
