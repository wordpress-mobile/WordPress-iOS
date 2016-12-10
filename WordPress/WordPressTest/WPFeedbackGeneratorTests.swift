import XCTest
@testable import WordPress

// MARK: - Enum mapping tests

@available(iOS 10, *)
class WPFeedbackGeneratorMappingTests: XCTestCase {
    func testNotificationFeedbackGeneratorMapping() {
        let successType = WPNotificationFeedbackType.success
        XCTAssertEqual(successType.systemFeedbackType.rawValue, UINotificationFeedbackType.success.rawValue)

        let warningType = WPNotificationFeedbackType.warning
        XCTAssertEqual(warningType.rawValue, UINotificationFeedbackType.warning.rawValue)

        let errorType = WPNotificationFeedbackType.error
        XCTAssertEqual(errorType.rawValue, UINotificationFeedbackType.error.rawValue)
    }

    func testImpactFeedbackGeneratorMapping() {
        let lightStyle = WPImpactFeedbackStyle.light
        XCTAssertEqual(lightStyle.systemFeedbackStyle.rawValue, UIImpactFeedbackStyle.light.rawValue)

        let mediumStyle = WPImpactFeedbackStyle.medium
        XCTAssertEqual(mediumStyle.systemFeedbackStyle.rawValue, UIImpactFeedbackStyle.medium.rawValue)

        let heavyStyle = WPImpactFeedbackStyle.heavy
        XCTAssertEqual(heavyStyle.systemFeedbackStyle.rawValue, UIImpactFeedbackStyle.heavy.rawValue)
    }
}

// MARK: - Notification generator tests

@available(iOS 10, *)
class WPNotificationFeedbackGeneratorTests: XCTestCase {
    private var mockGenerator: MockNotificationGenerator? = nil

    override func setUp() {
        super.setUp()

        mockGenerator = MockNotificationGenerator()
        WPNotificationFeedbackGenerator.generator = mockGenerator
    }

    func testUINotificationFeedbackGeneratorIsCalledForSuccess() {
        XCTAssertNil(mockGenerator?.notificationType)
        WPNotificationFeedbackGenerator.notificationOccurred(.success)
        XCTAssertEqual(mockGenerator?.notificationType, UINotificationFeedbackType.success)
    }

    func testUINotificationFeedbackGeneratorIsCalledForWarning() {
        XCTAssertNil(mockGenerator?.notificationType)
        WPNotificationFeedbackGenerator.notificationOccurred(.warning)
        XCTAssertEqual(mockGenerator?.notificationType, UINotificationFeedbackType.warning)
    }

    func testUINotificationFeedbackGeneratorIsCalledForError() {
        XCTAssertNil(mockGenerator?.notificationType)
        WPNotificationFeedbackGenerator.notificationOccurred(.error)
        XCTAssertEqual(mockGenerator?.notificationType, UINotificationFeedbackType.error)
    }
}

// MARK: - Impact generator tests

@available(iOS 10, *)
class WPImpactFeedbackGeneratorTests: XCTestCase {
    func testUIImpactFeedbackGeneratorIsCalledForLightImpact() {
        let (lightGenerator, mockGenerator) = impactGeneratorAndMockWithStyle(style: .light)

        XCTAssertFalse(mockGenerator.impactOccurredCalled)
        lightGenerator.impactOccurred()
        XCTAssertTrue(mockGenerator.impactOccurredCalled)
    }

    func testUIImpactFeedbackGeneratorIsCalledForMediumImpact() {
        let (mediumGenerator, mockGenerator) = impactGeneratorAndMockWithStyle(style: .medium)

        XCTAssertFalse(mockGenerator.impactOccurredCalled)
        mediumGenerator.impactOccurred()
        XCTAssertTrue(mockGenerator.impactOccurredCalled)
    }

    func testUIImpactFeedbackGeneratorIsCalledForHeavyImpact() {
        let (heavyGenerator, mockGenerator) = impactGeneratorAndMockWithStyle(style: .heavy)

        XCTAssertFalse(mockGenerator.impactOccurredCalled)
        heavyGenerator.impactOccurred()
        XCTAssertTrue(mockGenerator.impactOccurredCalled)
    }
}

// MARK: - Helpers

@available(iOS 10, *)
private class MockNotificationGenerator: WPNotificationFeedbackGeneratorConformance {
    var notificationType: UINotificationFeedbackType? = nil
    var notificationOccurredCalled: Bool {
        return notificationType != nil
    }

    func notificationOccurred(_ notificationType: UINotificationFeedbackType) {
        self.notificationType = notificationType
    }
}

private class MockImpactGenerator: WPImpactFeedbackGeneratorConformance {
    var impactOccurredCalled = false

    func impactOccurred() {
        impactOccurredCalled = true
    }
}

private func impactGeneratorAndMockWithStyle(style: WPImpactFeedbackStyle) -> (WPImpactFeedbackGenerator, MockImpactGenerator) {
    let mockGenerator = MockImpactGenerator()
    let generator = WPImpactFeedbackGenerator(style: style)
    generator.generator = mockGenerator

    return (generator, mockGenerator)
}
