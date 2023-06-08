import ScreenObject
import XCTest

public class OnboardingQuestionsPromptScreen: ScreenObject {
    private let skipButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Skip"]
    }

    var skipButton: XCUIElement { skipButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [skipButtonGetter],
            app: app,
            waitTimeout: 7
        )
    }

    public func selectSkip() throws -> MySiteScreen {
        skipButton.tap()

        return try MySiteScreen()
    }

    static func isLoaded() -> Bool {
        (try? OnboardingQuestionsPromptScreen().isLoaded) ?? false
    }

    public func skipOnboarding() throws {
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
        }
    }
}
