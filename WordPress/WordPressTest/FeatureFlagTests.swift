import XCTest
@testable import WordPress

enum MockFeatureFlag: OverrideableFlag {
    case enabledFeature
    case disabledFeature
    case nonOverrideableFeature

    case remotelyEnabledLocallyEnabledFeature
    case remotelyEnabledLocallyDisabledFeature
    case remotelyDisabledLocallyEnabledFeature
    case remotelyDisabledLocallyDisabledFeature
    case remotelyUndefinedLocallyEnabledFeature
    case remotelyUndefinedLocallyDisabledFeature

    static var remoteCases: [MockFeatureFlag] {
        return [
            .remotelyEnabledLocallyEnabledFeature,
            .remotelyEnabledLocallyDisabledFeature,
            .remotelyDisabledLocallyEnabledFeature,
            .remotelyDisabledLocallyDisabledFeature,
            .remotelyUndefinedLocallyEnabledFeature,
            .remotelyUndefinedLocallyDisabledFeature,
        ]
    }

    var enabled: Bool {
        switch self {
        case .enabledFeature:
            return true
        case .disabledFeature:
            return false
        case .nonOverrideableFeature:
            return true
        case .remotelyEnabledLocallyEnabledFeature,
             .remotelyDisabledLocallyEnabledFeature,
             .remotelyUndefinedLocallyEnabledFeature:
            return true
        case .remotelyEnabledLocallyDisabledFeature,
             .remotelyDisabledLocallyDisabledFeature,
             .remotelyUndefinedLocallyDisabledFeature:
            return false
        }
    }

    var canOverride: Bool {
        return self != .nonOverrideableFeature
    }

    var description: String {
        switch self {
        case .enabledFeature:
            return "Enabled feature"
        case .disabledFeature:
            return "Disabled feature"
        case .nonOverrideableFeature:
            return "Non overrideable feature"
        case .remotelyEnabledLocallyEnabledFeature:
            return "Remotely Enabled, Locally Enabled Feature"
        case .remotelyEnabledLocallyDisabledFeature:
            return "Remote Enabled, Locally Disabled Feature"
        case .remotelyDisabledLocallyEnabledFeature:
            return "Remotely Disabled, Locally Enabled Feature"
        case .remotelyDisabledLocallyDisabledFeature:
            return "Remotely Disabled, Locally Disabled Feature"
        case .remotelyUndefinedLocallyEnabledFeature:
            return "Locally Enabled Feature with no corresponding remote key"
        case .remotelyUndefinedLocallyDisabledFeature:
            return "Locally Disabled Feature with no corresponding remote key"
        }
    }

    var remoteKey: String? {
        switch self {
        case .remotelyEnabledLocallyEnabledFeature,
             .remotelyEnabledLocallyDisabledFeature,
             .remotelyDisabledLocallyEnabledFeature,
             .remotelyDisabledLocallyDisabledFeature:
            return self.description
        case .remotelyUndefinedLocallyEnabledFeature,
             .remotelyUndefinedLocallyDisabledFeature:
            return nil
        default:
            return nil
        }
    }

    var remoteValue: Bool? {
        switch self {
        case .remotelyEnabledLocallyEnabledFeature,
             .remotelyEnabledLocallyDisabledFeature:
            return true
        case .remotelyDisabledLocallyEnabledFeature,
             .remotelyDisabledLocallyDisabledFeature:
            return false
        case .remotelyUndefinedLocallyEnabledFeature,
             .remotelyUndefinedLocallyDisabledFeature:
            return nil
        default:
            return nil
        }
    }

    var toFeatureFlag: WordPressKit.FeatureFlag? {
        guard
            let remoteKey = remoteKey,
            let remoteValue = remoteValue
        else {
            return nil
        }

        return WordPressKit.FeatureFlag(title: remoteKey, value: remoteValue)
    }
}

class FeatureFlagTests: XCTestCase {
    var store: FeatureFlagOverrideStore!

    override func setUp() {
        store = FeatureFlagOverrideStore(store: EphemeralKeyValueDatabase())
    }

    func testFeatureFlagIsNotOverriddenByDefault() {
        let flag = MockFeatureFlag.enabledFeature
        XCTAssertFalse(store.isOverridden(flag))
    }

    func testEnabledFeatureFlagValueIsOverridden() {
        let flag = MockFeatureFlag.enabledFeature

        XCTAssertNil(store.overriddenValue(for: flag))
        try? store.override(flag, withValue: false)

        let value = store.overriddenValue(for: flag)
        XCTAssertNotNil(value)
        XCTAssert(value == false)
    }

    func testDisabledFeatureFlagValueIsOverridden() {
        let flag = MockFeatureFlag.disabledFeature

        XCTAssertNil(store.overriddenValue(for: flag))
        try? store.override(flag, withValue: true)

        let value = store.overriddenValue(for: flag)
        XCTAssertNotNil(value)
        XCTAssert(value == true)
    }

    func testNonOverrideableFeatureFlagCannotBeOverridden() {
        let flag = MockFeatureFlag.nonOverrideableFeature

        try? store.override(flag, withValue: false)
        XCTAssertFalse(store.isOverridden(flag))
    }

    func testEnabledFeatureFlagValueIsNotOverriddenWhenResetToNormalState() {
        let flag = MockFeatureFlag.enabledFeature

        XCTAssertFalse(store.isOverridden(flag))

        try? store.override(flag, withValue: false)
        XCTAssertTrue(store.isOverridden(flag))

        try? store.override(flag, withValue: true)
        XCTAssertFalse(store.isOverridden(flag))
    }

    func testDisabledFeatureFlagValueIsNotOverriddenWhenResetToNormalState() {
        let flag = MockFeatureFlag.disabledFeature

        XCTAssertFalse(store.isOverridden(flag))

        try? store.override(flag, withValue: true)
        XCTAssertTrue(store.isOverridden(flag))

        try? store.override(flag, withValue: false)
        XCTAssertFalse(store.isOverridden(flag))
    }
}
