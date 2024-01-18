import ScreenObject
import XCTest

public class PlanSelectionScreen: ScreenObject {

    private let webViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.webViews.firstMatch
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ webViewGetter ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? PlanSelectionScreen().isLoaded) ?? false
    }

    @discardableResult
    public func verifyPlanSelectionScreenLoaded() -> Self {
        XCTAssertTrue(PlanSelectionScreen.isLoaded(), "\"Plan Selection\" screen isn't loaded.")
        return self
    }

    /// Testing mocked web view page
    /// API-Mocks/../assets/mocks/files/plans_yearly.html
    @discardableResult
    public func selectPlan() throws -> PlanSelectionScreen {
        app.webViews.firstMatch.links["Select plan"].tap()
        return self
    }

    /// Testing mocked web view page
    /// API-Mocks/../assets/mocks/files/checkout.html
    @discardableResult
    public func purchase() throws -> DomainResultScreen {
        app.webViews.firstMatch.links["Purchase"].tap()
        return try DomainResultScreen()
    }
}
