import Foundation
import Testing
import WordPressShared
@testable import WordPress

/// Covers how the New Stats rollout resolves: `ios_new_stats` drives enrollment, but an
/// explicit choice by the user wins over it in both directions.
struct NewStatsFeatureFlagTests {

    /// The override's storage key is built from `description` — `OverridableFlag` refines
    /// `CustomStringConvertible`, so `String(describing:)` resolves through it rather than
    /// reflecting the case name. That string is what carries every pre-existing opt-in
    /// across the move from `FeatureFlag.newStats` to `RemoteFeatureFlag.newStats`: fresh
    /// install pins, announcement accepters and manual opt-ins all live under it.
    ///
    /// Renaming the flag's user-visible label would therefore re-enrol all of them. If this
    /// test fails, the label changed — restore it rather than updating the expectation.
    @Test("The override key carries over from the local flag")
    func overrideKeyIsStable() {
        #expect(RemoteFeatureFlag.newStats.key == "ff-override-New Stats")
        #expect(RemoteFeatureFlag.newStats.remoteKey == "ios_new_stats")
    }

    @Test("Resolves to the compile-time default until the flag has been fetched")
    func defaultsToOffBeforeTheFirstFetch() {
        #expect(RemoteFeatureFlag.newStats.defaultValue == false)
        #expect(resolve(storedChoice: nil, remote: nil) == false)
    }

    /// A `nil` stored choice means the user never expressed one — which includes everybody
    /// who dismissed the old announcement screen. A `nil` remote value means the flag has
    /// not been fetched yet, so the compile-time default applies.
    @Test("An explicit choice wins over the remote flag", arguments: [
        (storedChoice: Bool?.none, remote: Bool?.none, expected: false),
        (storedChoice: Bool?.none, remote: Bool?.some(true), expected: true),
        (storedChoice: Bool?.none, remote: Bool?.some(false), expected: false),
        (storedChoice: Bool?.some(true), remote: Bool?.none, expected: true),
        (storedChoice: Bool?.some(true), remote: Bool?.some(true), expected: true),
        (storedChoice: Bool?.some(true), remote: Bool?.some(false), expected: true),
        (storedChoice: Bool?.some(false), remote: Bool?.none, expected: false),
        (storedChoice: Bool?.some(false), remote: Bool?.some(true), expected: false),
        (storedChoice: Bool?.some(false), remote: Bool?.some(false), expected: false),
    ])
    func resolution(_ scenario: (storedChoice: Bool?, remote: Bool?, expected: Bool)) {
        let actual = resolve(storedChoice: scenario.storedChoice, remote: scenario.remote)
        #expect(actual == scenario.expected)
    }

    @Test("Opting out keeps classic Stats even once the rollout reaches the user")
    func optingOutSurvivesTheRollout() {
        let overrideStore = makeOverrideStore()
        overrideStore.override(RemoteFeatureFlag.newStats, withValue: false)

        // The choice has to be persisted, not dropped for matching the current default:
        // otherwise it is indistinguishable from never having chosen.
        #expect(overrideStore.isOverridden(RemoteFeatureFlag.newStats))
        #expect(resolve(in: overrideStore, remote: true) == false)
    }

    @Test("The fresh-install pin survives the remote flag being turned off")
    func freshInstallPinSurvivesTheFlagBeingTurnedOff() {
        // What `WordPressAppDelegate.updateFeatureFlags()` writes on a fresh install.
        let overrideStore = makeOverrideStore()
        overrideStore.override(RemoteFeatureFlag.newStats, withValue: true)

        #expect(overrideStore.isOverridden(RemoteFeatureFlag.newStats))
        #expect(resolve(in: overrideStore, remote: false) == true)
    }

    @Test("Clearing the stored choice hands control back to the remote flag")
    func removingTheChoiceRestoresRemoteControl() {
        let overrideStore = makeOverrideStore()
        overrideStore.override(RemoteFeatureFlag.newStats, withValue: false)
        overrideStore.removeOverride(for: RemoteFeatureFlag.newStats)

        #expect(!overrideStore.isOverridden(RemoteFeatureFlag.newStats))
        #expect(resolve(in: overrideStore, remote: true) == true)
    }

    // MARK: - Helpers

    /// An override store backed by memory, so a stored choice can't leak into the
    /// simulator's shared defaults and look like a real user opting out.
    private func makeOverrideStore() -> FeatureFlagOverrideStore {
        FeatureFlagOverrideStore(store: EphemeralKeyValueDatabase())
    }

    /// A remote store backed by memory: an unset flag resolves to `nil` rather than
    /// falling through to whatever the simulator last fetched.
    private func makeRemoteStore(value: Bool?) -> RemoteFeatureFlagStoreMock {
        let store = RemoteFeatureFlagStoreMock(persistenceStore: InMemoryUserDefaults())
        switch value {
        case .some(true):
            store.enabledFeatureFlags = [RemoteFeatureFlag.newStats.remoteKey]
        case .some(false):
            store.disabledFeatureFlag = [RemoteFeatureFlag.newStats.remoteKey]
        case .none:
            break
        }
        return store
    }

    private func resolve(storedChoice: Bool?, remote: Bool?) -> Bool {
        let overrideStore = makeOverrideStore()
        if let storedChoice {
            overrideStore.override(RemoteFeatureFlag.newStats, withValue: storedChoice)
        }
        return resolve(in: overrideStore, remote: remote)
    }

    private func resolve(in overrideStore: FeatureFlagOverrideStore, remote: Bool?) -> Bool {
        RemoteFeatureFlag.newStats.enabled(
            using: makeRemoteStore(value: remote),
            overrideStore: overrideStore
        )
    }
}
