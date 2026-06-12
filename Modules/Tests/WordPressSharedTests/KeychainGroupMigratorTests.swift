import BuildSettingsKit
import Foundation
import Security
import Testing
@testable import WordPressShared

private final class FlagStoreFake: KeychainMigrationFlagStore {
    var storage: [String: Any] = [:]

    func bool(forKey defaultName: String) -> Bool { storage[defaultName] as? Bool ?? false }
    func integer(forKey defaultName: String) -> Int { storage[defaultName] as? Int ?? 0 }
    func set(_ value: Bool, forKey defaultName: String) { storage[defaultName] = value }
    func set(_ value: Int, forKey defaultName: String) { storage[defaultName] = value }
}

extension KeychainStubSuites {
    @Suite(.serialized)
    struct KeychainGroupMigratorTests {
        private let privateGroup = "team.private.wordpress"
        private let sharedGroup = "team.shared"
        private let localDefaults = FlagStoreFake()
        private let sharedDefaults = FlagStoreFake()

        init() {
            KeychainStub.reset()
        }

        private func makeMigrator(
            brand: AppBrand = .wordpress
        ) -> KeychainGroupMigrator {
            KeychainGroupMigrator(
                brand: brand,
                privateGroup: privateGroup,
                sharedGroup: sharedGroup,
                localDefaults: localDefaults,
                sharedDefaults: sharedDefaults,
                keychainUtils: KeychainStub.self
            )!
        }

        @Test func initFailsForReaderOrMissingSharedGroup() {
            #expect(
                KeychainGroupMigrator(
                    brand: .reader,
                    privateGroup: privateGroup,
                    sharedGroup: sharedGroup,
                    localDefaults: localDefaults,
                    sharedDefaults: sharedDefaults,
                    keychainUtils: KeychainStub.self
                ) == nil
            )
            #expect(
                KeychainGroupMigrator(
                    brand: .wordpress,
                    privateGroup: privateGroup,
                    sharedGroup: nil,
                    localDefaults: localDefaults,
                    sharedDefaults: sharedDefaults,
                    keychainUtils: KeychainStub.self
                ) == nil
            )
        }

        @Test func copyMovesItemsAndSetsFlags() {
            KeychainStub.seed(group: sharedGroup, service: "svc1", username: "u1", password: "p1")
            KeychainStub.seed(group: sharedGroup, service: "svc2", username: "u2", password: "p2")

            makeMigrator().copyIfNeeded()

            #expect(KeychainStub.password(group: privateGroup, service: "svc1", username: "u1") == "p1")
            #expect(KeychainStub.password(group: privateGroup, service: "svc2", username: "u2") == "p2")
            // Originals stay; the sweep removes them later.
            #expect(KeychainStub.password(group: sharedGroup, service: "svc1", username: "u1") == "p1")
            #expect(localDefaults.integer(forKey: "keychain_access_group_migration_version") == 1)
            #expect(
                sharedDefaults.integer(forKey: "keychain_private_copy_done.wordpress")
                    == KeychainGroupMigrator.migrationVersion
            )
        }

        @Test func copySkippedWhenMarkerCurrent() {
            localDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_access_group_migration_version")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")

            makeMigrator().copyIfNeeded()

            #expect(KeychainStub.password(group: privateGroup, service: "svc", username: "u") == nil)
        }

        @Test func copyFailureLeavesMarkerUnset() {
            KeychainStub.getAllPasswordsError = NSError(domain: "KeychainStub", code: Int(errSecInteractionNotAllowed))

            makeMigrator().copyIfNeeded()

            #expect(localDefaults.integer(forKey: "keychain_access_group_migration_version") == 0)
            #expect(sharedDefaults.integer(forKey: "keychain_private_copy_done.wordpress") == 0)
        }

        @Test func sweepBlockedWithoutCounterpartFlag() {
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.wordpress")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")

            makeMigrator().sweepIfSafe()

            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "u") == "p")
            #expect(!sharedDefaults.bool(forKey: "keychain_shared_sweep_done"))
        }

        @Test func sweepBlockedBeforeOwnCopy() {
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")

            makeMigrator().sweepIfSafe()

            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "u") == "p")
        }

        @Test func sweepPreservesHandoffItem() {
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.wordpress")
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.jetpack")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")
            KeychainStub.seed(
                group: sharedGroup,
                service: "public-api.wordpress.com",
                username: "acct",
                password: "token"
            )

            makeMigrator().sweepIfSafe()

            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "u") == nil)
            #expect(
                KeychainStub.password(group: sharedGroup, service: "public-api.wordpress.com", username: "acct")
                    == "token"
            )
            #expect(sharedDefaults.bool(forKey: "keychain_shared_sweep_done"))
        }

        @Test func sweepRunsWhenCounterpartCopied() {
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.wordpress")
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.jetpack")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")

            makeMigrator().sweepIfSafe()

            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "u") == nil)
            #expect(sharedDefaults.bool(forKey: "keychain_shared_sweep_done"))
        }

        @Test func sweepSkippedWhenAlreadyDone() {
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.wordpress")
            sharedDefaults.set(true, forKey: "keychain_shared_sweep_done")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")

            makeMigrator().sweepIfSafe()

            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "u") == "p")
        }

        @Test func copyWithEmptyGroupSetsMarkerAndFlag() {
            KeychainStub.getAllPasswordsError = NSError(domain: "KeychainStub", code: Int(errSecItemNotFound))

            makeMigrator().copyIfNeeded()

            #expect(
                localDefaults.integer(forKey: "keychain_access_group_migration_version")
                    == KeychainGroupMigrator.migrationVersion
            )
            #expect(
                sharedDefaults.integer(forKey: "keychain_private_copy_done.wordpress")
                    == KeychainGroupMigrator.migrationVersion
            )
        }

        @Test func sweepBlockedWhenCounterpartCopiedAtOlderVersion() {
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.wordpress")
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion - 1, forKey: "keychain_private_copy_done.jetpack")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")

            makeMigrator().sweepIfSafe()

            #expect(KeychainStub.password(group: sharedGroup, service: "svc", username: "u") == "p")
            #expect(!sharedDefaults.bool(forKey: "keychain_shared_sweep_done"))
        }

        @Test func sweepRetriesWhenDeleteFails() {
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.wordpress")
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.jetpack")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")
            KeychainStub.deleteError = NSError(domain: "KeychainStub", code: Int(errSecInteractionNotAllowed))

            makeMigrator().sweepIfSafe()

            #expect(!sharedDefaults.bool(forKey: "keychain_shared_sweep_done"))
        }

        @Test func sweepWithEmptyGroupMarksDone() {
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.wordpress")
            sharedDefaults.set(KeychainGroupMigrator.migrationVersion, forKey: "keychain_private_copy_done.jetpack")
            KeychainStub.getAllPasswordsError = NSError(domain: "KeychainStub", code: Int(errSecItemNotFound))

            makeMigrator().sweepIfSafe()

            #expect(sharedDefaults.bool(forKey: "keychain_shared_sweep_done"))
        }

        @Test func copySkipsCounterpartAuthToken() {
            KeychainStub.seed(
                group: sharedGroup,
                service: "jetpack.public-api.wordpress.com",
                username: "u",
                password: "jp-token"
            )
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "p")

            makeMigrator(brand: .wordpress).copyIfNeeded()

            #expect(
                KeychainStub.password(group: privateGroup, service: "jetpack.public-api.wordpress.com", username: "u")
                    == nil
            )
            #expect(KeychainStub.password(group: privateGroup, service: "svc", username: "u") == "p")
        }

        @Test func copyKeepsOwnAuthToken() {
            KeychainStub.seed(
                group: sharedGroup,
                service: "jetpack.public-api.wordpress.com",
                username: "u",
                password: "jp-token"
            )

            makeMigrator(brand: .jetpack).copyIfNeeded()

            #expect(
                KeychainStub.password(group: privateGroup, service: "jetpack.public-api.wordpress.com", username: "u")
                    == "jp-token"
            )
        }

        @Test func retriedCopyDoesNotOverwriteNewerPrivateItem() {
            KeychainStub.seed(group: privateGroup, service: "svc", username: "u", password: "newer-pw")
            KeychainStub.seed(group: sharedGroup, service: "svc", username: "u", password: "older-pw")
            KeychainStub.seed(group: sharedGroup, service: "svc2", username: "u2", password: "p2")

            makeMigrator().copyIfNeeded()

            #expect(KeychainStub.password(group: privateGroup, service: "svc", username: "u") == "newer-pw")
            #expect(KeychainStub.password(group: privateGroup, service: "svc2", username: "u2") == "p2")
            #expect(
                localDefaults.integer(forKey: "keychain_access_group_migration_version")
                    == KeychainGroupMigrator.migrationVersion
            )
        }
    }
}
