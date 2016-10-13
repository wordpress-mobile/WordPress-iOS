import XCTest
@testable import WordPress

// MARK: - Enum mapping tests

@available(iOS 10, *)
class WPFeedbackGeneratorMappingTests: XCTestCase {
    func testNotificationFeedbackGeneratorMapping() {
        let successType = WPNotificationFeedbackType.Success
        XCTAssertEqual(successType.systemFeedbackType.rawValue, UINotificationFeedbackType.Success.rawValue)

        let warningType = WPNotificationFeedbackType.Warning
        XCTAssertEqual(warningType.rawValue, UINotificationFeedbackType.Warning.rawValue)

        let errorType = WPNotificationFeedbackType.Error
        XCTAssertEqual(errorType.rawValue, UINotificationFeedbackType.Error.rawValue)
    }

    func testImpactFeedbackGeneratorMapping() {
        let lightStyle = WPImpactFeedbackStyle.Light
        XCTAssertEqual(lightStyle.systemFeedbackStyle.rawValue, UIImpactFeedbackStyle.Light.rawValue)

        let mediumStyle = WPImpactFeedbackStyle.Medium
        XCTAssertEqual(mediumStyle.systemFeedbackStyle.rawValue, UIImpactFeedbackStyle.Medium.rawValue)

        let heavyStyle = WPImpactFeedbackStyle.Heavy
        XCTAssertEqual(heavyStyle.systemFeedbackStyle.rawValue, UIImpactFeedbackStyle.Heavy.rawValue)
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
        WPNotificationFeedbackGenerator.notificationOccurred(.Success)
        XCTAssertEqual(mockGenerator?.notificationType, UINotificationFeedbackType.Success)
    }

    func testUINotificationFeedbackGeneratorIsCalledForWarning() {
        XCTAssertNil(mockGenerator?.notificationType)
        WPNotificationFeedbackGenerator.notificationOccurred(.Warning)
        XCTAssertEqual(mockGenerator?.notificationType, UINotificationFeedbackType.Warning)
    }

    func testUINotificationFeedbackGeneratorIsCalledForError() {
        XCTAssertNil(mockGenerator?.notificationType)
        WPNotificationFeedbackGenerator.notificationOccurred(.Error)
        XCTAssertEqual(mockGenerator?.notificationType, UINotificationFeedbackType.Error)
    }
}

// MARK: - Impact generator tests

@available(iOS 10, *)
class WPImpactFeedbackGeneratorTests: XCTestCase {
    func testUIImpactFeedbackGeneratorIsCalledForLightImpact() {
        let (lightGenerator, mockGenerator) = impactGeneratorAndMockWithStyle(.Light)

        XCTAssertFalse(mockGenerator.impactOccurredCalled)
        lightGenerator.impactOccurred()
        XCTAssertTrue(mockGenerator.impactOccurredCalled)
    }

    func testUIImpactFeedbackGeneratorIsCalledForMediumImpact() {
        let (mediumGenerator, mockGenerator) = impactGeneratorAndMockWithStyle(.Medium)

        XCTAssertFalse(mockGenerator.impactOccurredCalled)
        mediumGenerator.impactOccurred()
        XCTAssertTrue(mockGenerator.impactOccurredCalled)
    }

    func testUIImpactFeedbackGeneratorIsCalledForHeavyImpact() {
        let (heavyGenerator, mockGenerator) = impactGeneratorAndMockWithStyle(.Heavy)

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

    func notificationOccurred(notificationType: UINotificationFeedbackType) {
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
