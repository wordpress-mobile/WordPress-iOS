import XCTest
@testable import WordPress

// MARK: - Enum mapping tests

@available(iOS 10, *)
class WPFeedbackGeneratorTests: XCTestCase {
    func testNotificationFeedbackGeneratorMapping() {
        let successType = WPNotificationFeedbackType.Success
        XCTAssertEqual(successType.rawValue, successType.systemFeedbackType.rawValue)

        let warningType = WPNotificationFeedbackType.Warning
        XCTAssertEqual(warningType.rawValue, warningType.systemFeedbackType.rawValue)

        let errorType = WPNotificationFeedbackType.Error
        XCTAssertEqual(errorType.rawValue, errorType.systemFeedbackType.rawValue)
    }

    func testImpactFeedbackGeneratorMapping() {
        let lightStyle = WPImpactFeedbackStyle.Light
        XCTAssertEqual(lightStyle.rawValue, lightStyle.systemFeedbackStyle.rawValue)

        let mediumStyle = WPImpactFeedbackStyle.Medium
        XCTAssertEqual(mediumStyle.rawValue, mediumStyle.systemFeedbackStyle.rawValue)

        let heavyStyle = WPImpactFeedbackStyle.Heavy
        XCTAssertEqual(heavyStyle.rawValue, heavyStyle.systemFeedbackStyle.rawValue)
    }
}

// MARK: - Notification generator tests

@available(iOS 10, *)
extension WPFeedbackGeneratorTests {
    func testUINotificationFeedbackGeneratorIsCalledForSuccess() {
        let mockGenerator = MockNotificationGenerator()
        WPNotificationFeedbackGenerator.generator = mockGenerator

        XCTAssertNil(mockGenerator.notificationType)
        WPNotificationFeedbackGenerator.notificationOccurred(.Success)
        XCTAssertEqual(mockGenerator.notificationType, UINotificationFeedbackType.Success)
    }

    func testUINotificationFeedbackGeneratorIsCalledForWarning() {
        let mockGenerator = MockNotificationGenerator()
        WPNotificationFeedbackGenerator.generator = mockGenerator

        XCTAssertNil(mockGenerator.notificationType)
        WPNotificationFeedbackGenerator.notificationOccurred(.Warning)
        XCTAssertEqual(mockGenerator.notificationType, UINotificationFeedbackType.Warning)
    }

    func testUINotificationFeedbackGeneratorIsCalledForError() {
        let mockGenerator = MockNotificationGenerator()
        WPNotificationFeedbackGenerator.generator = mockGenerator

        XCTAssertNil(mockGenerator.notificationType)
        WPNotificationFeedbackGenerator.notificationOccurred(.Error)
        XCTAssertEqual(mockGenerator.notificationType, UINotificationFeedbackType.Error)
    }
}

// MARK: - Impact generator tests

@available(iOS 10, *)
extension WPFeedbackGeneratorTests {
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
