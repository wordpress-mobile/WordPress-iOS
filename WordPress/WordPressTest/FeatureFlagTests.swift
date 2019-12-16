import XCTest
@testable import WordPress

fileprivate enum MockFeatureFlag: OverrideableFlag {
    case enabledFeature
    case disabledFeature
    case nonOverrideableFeature

    var enabled: Bool {
        switch self {
        case .enabledFeature:
            return true
        case .disabledFeature:
            return false
        case .nonOverrideableFeature:
            return true
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
        }
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
