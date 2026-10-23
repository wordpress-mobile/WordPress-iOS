import Foundation
import Security
import Testing

@testable import WordPressShared

extension KeychainStubSuites {
    @Suite(.serialized)
    struct SynchronizableAppKeychainTests {
        private let privateGroup = "team.private"
        private let sharedGroup = "team.shared"
        private let store = FakeSynchronizableStore()

        init() {
            KeychainStub.reset()
        }

        private func makeDeviceOnlyKeychain() -> AppKeychain {
            AppKeychain(privateGroup: privateGroup, sharedGroup: sharedGroup, keychainUtils: KeychainStub.self)
        }

        private func makeKeychain() -> SynchronizableAppKeychain {
            SynchronizableAppKeychain(store: store, deviceOnly: makeDeviceOnlyKeychain())
        }

        private func deviceOnlyPassword(group: String) -> String? {
            KeychainStub.password(group: group, service: "svc", username: "user")
        }

        // MARK: Reads

        @Test func readsSyncedItem() throws {
            store.items["svc|user"] = "synced-pw"

            #expect(try makeKeychain().getPassword(for: "user", serviceName: "svc") == "synced-pw")
        }

        @Test func readPrefersSyncedItemOverDeviceOnlyItem() throws {
            store.items["svc|user"] = "synced-pw"
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "device-pw")

            #expect(try makeKeychain().getPassword(for: "user", serviceName: "svc") == "synced-pw")
        }

        @Test func readMovesDeviceOnlyItemIntoSyncedStore() throws {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "device-pw")

            #expect(try makeKeychain().getPassword(for: "user", serviceName: "svc") == "device-pw")
            #expect(store.items["svc|user"] == "device-pw")
            #expect(deviceOnlyPassword(group: privateGroup) == nil)
        }

        @Test func readMovesLegacySharedGroupItemIntoSyncedStoreAndKeepsSharedCopy() throws {
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "shared-pw")

            #expect(try makeKeychain().getPassword(for: "user", serviceName: "svc") == "shared-pw")
            #expect(store.items["svc|user"] == "shared-pw")
            #expect(deviceOnlyPassword(group: privateGroup) == nil)
            // The other app may still read its copy from the shared group.
            #expect(deviceOnlyPassword(group: sharedGroup) == "shared-pw")
        }

        @Test func readKeepsNewerSyncedValueThatArrivesDuringMigration() throws {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "device-pw")
            store.valueArrivingBeforeAdd = "newer-pw"

            #expect(try makeKeychain().getPassword(for: "user", serviceName: "svc") == "newer-pw")
            #expect(store.items["svc|user"] == "newer-pw")
            #expect(deviceOnlyPassword(group: privateGroup) == nil)
        }

        @Test func readKeepsDeviceOnlyItemWhenSyncedWriteFails() throws {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "device-pw")
            store.writeError = NSError(domain: NSOSStatusErrorDomain, code: Int(errSecInteractionNotAllowed))

            #expect(try makeKeychain().getPassword(for: "user", serviceName: "svc") == "device-pw")
            #expect(deviceOnlyPassword(group: privateGroup) == "device-pw")
        }

        @Test func readSurfacesSyncedStoreFailureWithoutFallingBack() {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "device-pw")
            store.readError = NSError(domain: NSOSStatusErrorDomain, code: Int(errSecInteractionNotAllowed))

            #expect(throws: (any Error).self) {
                try makeKeychain().getPassword(for: "user", serviceName: "svc")
            }
            #expect(deviceOnlyPassword(group: privateGroup) == "device-pw")
        }

        @Test func readThrowsWhenMissingEverywhere() {
            #expect(throws: (any Error).self) {
                try makeKeychain().getPassword(for: "user", serviceName: "svc")
            }
        }

        // MARK: Writes

        @Test func writeGoesToSyncedStoreAndRemovesPrivateCopyOnly() throws {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "old-pw")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "old-pw")

            try makeKeychain().setPassword(for: "user", to: "new-pw", serviceName: "svc")

            #expect(store.items["svc|user"] == "new-pw")
            #expect(deviceOnlyPassword(group: privateGroup) == nil)
            #expect(deviceOnlyPassword(group: sharedGroup) == "old-pw")
        }

        @Test func writeSucceedsWhenDeviceOnlyCleanupFails() throws {
            KeychainStub.deleteError = NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecInteractionNotAllowed))

            try makeKeychain().setPassword(for: "user", to: "new-pw", serviceName: "svc")

            #expect(store.items["svc|user"] == "new-pw")
        }

        @Test func writeSurfacesSyncedStoreFailure() {
            store.writeError = NSError(domain: NSOSStatusErrorDomain, code: Int(errSecInteractionNotAllowed))

            #expect(throws: (any Error).self) {
                try makeKeychain().setPassword(for: "user", to: "new-pw", serviceName: "svc")
            }
        }

        // MARK: Deletes

        @Test func deleteRemovesSyncedAndDeviceOnlyCopies() throws {
            store.items["svc|user"] = "synced-pw"
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "device-pw")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "user", password: "shared-pw")

            try makeKeychain().setPassword(for: "user", to: nil, serviceName: "svc")

            #expect(store.items["svc|user"] == nil)
            #expect(deviceOnlyPassword(group: privateGroup) == nil)
            #expect(deviceOnlyPassword(group: sharedGroup) == nil)
        }

        @Test func deleteSucceedsWhenNothingIsStored() throws {
            try makeKeychain().setPassword(for: "user", to: nil, serviceName: "svc")
        }

        @Test func deleteRemovesDeviceOnlyCopyEvenWhenSyncedDeleteFails() {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "user", password: "device-pw")
            store.deleteError = NSError(domain: NSOSStatusErrorDomain, code: Int(errSecInteractionNotAllowed))

            #expect(throws: (any Error).self) {
                try makeKeychain().setPassword(for: "user", to: nil, serviceName: "svc")
            }
            #expect(deviceOnlyPassword(group: privateGroup) == nil)
        }

        // MARK: `synchronizable`

        @Test func appKeychainSynchronizableIsSynchronizableAppKeychain() {
            #expect(makeDeviceOnlyKeychain().synchronizable is SynchronizableAppKeychain)
        }

        @Test func synchronizableAppKeychainIsItsOwnSynchronizableVariant() {
            let keychain = makeKeychain()
            #expect(keychain.synchronizable as AnyObject === keychain)
        }

        @Test func otherKeychainsAreTheirOwnSynchronizableVariant() throws {
            let keychain = try #require(SharedKeychain(group: sharedGroup, keychainUtils: KeychainStub.self))
            #expect(keychain.synchronizable as AnyObject === keychain)
        }
    }
}

/// In-memory stand-in for the synced keychain items, keyed by "service|username".
private final class FakeSynchronizableStore: SynchronizableKeychainStore {
    var items: [String: String] = [:]
    var readError: Error?
    var writeError: Error?
    var deleteError: Error?
    /// Saved just before `addPassword` runs, like a value arriving through iCloud Keychain.
    var valueArrivingBeforeAdd: String?

    func password(for username: String, serviceName: String) throws -> String? {
        if let readError { throw readError }
        return items["\(serviceName)|\(username)"]
    }

    func setPassword(_ password: String, for username: String, serviceName: String) throws {
        if let writeError { throw writeError }
        items["\(serviceName)|\(username)"] = password
    }

    func addPassword(_ password: String, for username: String, serviceName: String) throws -> Bool {
        if let writeError { throw writeError }
        if let valueArrivingBeforeAdd {
            items["\(serviceName)|\(username)"] = valueArrivingBeforeAdd
        }
        guard items["\(serviceName)|\(username)"] == nil else { return false }
        items["\(serviceName)|\(username)"] = password
        return true
    }

    func deletePassword(for username: String, serviceName: String) throws {
        if let deleteError { throw deleteError }
        items["\(serviceName)|\(username)"] = nil
    }
}
