import ScreenObject
import XCTest

public class PrologueScreen: ScreenObject {

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Prologue Continue Button"]
    }

    private let siteAddressButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Prologue Self Hosted Button"]
    }

    var continueButton: XCUIElement { continueButtonGetter(app) }
    var siteAddressButton: XCUIElement { siteAddressButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [continueButtonGetter, siteAddressButtonGetter],
            app: app,
            waitTimeout: 3
        )
    }

    public func selectContinue() throws -> GetStartedScreen {
        continueButton.tap()

        return try GetStartedScreen()
    }

    public func selectSiteAddress() throws -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return try LoginSiteAddressScreen()
    }

    public static func isLoaded(app: XCUIApplication = XCUIApplication()) -> Bool {
        (try? PrologueScreen(app: app).isLoaded) ?? false
    }
}
