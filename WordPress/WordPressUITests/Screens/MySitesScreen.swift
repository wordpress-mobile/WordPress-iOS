import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let blogsTable = "Blogs" // there's not actually static text here. we'll need an accessibilityID
    static let cancelButton = "cancel-button"
    static let plusButton = "add-site-button"
    static let addSelfHostedSiteButton = "Add self-hosted site"
}

class MySitesScreen: BaseScreen {
    let blogsTable: XCUIElement
    let cancelButton: XCUIElement
    let plusButton: XCUIElement
    let addSelfHostedSiteButton: XCUIElement

    init() {
        let app = XCUIApplication()
        blogsTable = app.staticTexts[ElementStringIDs.blogsTable]
        cancelButton = app.buttons[ElementStringIDs.cancelButton]
        plusButton = app.buttons[ElementStringIDs.plusButton]
        addSelfHostedSiteButton = app.staticTexts[ElementStringIDs.addSelfHostedSiteButton]
        // need to add "+" button here for Add Site options. Something like:
        // let plusButton = XCUIApplication().buttons["+"] accessibility inspector says it has the Label: "Add", but no accessibilityIdentifier
        // And then the action sheet "add Self-hosted site" option.
        // then we'll need a function to tap + and "add self-hosted site", which should return the self-hosted login flow - LoginSiteAddressScreen

        super.init(element: plusButton) // using plusButton for the super.init since blogsTable isn't identified
    }

   // func tapPlusButton() {
     //   plusButton.tap()
        // seems like this needs to somehow return the action sheet so that the "Add self-hosted site" button is available for addSelfHostedSite(). ActionSheetComponent exists, but presents options for adding a blog post or page. Maybe I can copy ActionSheetComponent and make BlogListActionSheetComponent? Of course I need to be able to access the "add" button before any of that matters.
 //   }

    func addSelfHostedSite() -> LoginSiteAddressScreen {
        plusButton.tap()
        XCUIApplication().buttons["Add self-hosted site"].tap()
        return LoginSiteAddressScreen()
    }

    func closeModal() -> MySiteScreen {
        cancelButton.tap()
        return MySiteScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["Blogs"].exists // oh. so because this is defined in the init just to be used by the super.init, it's not in scope to be used outside the init? Ok, so yes I should re-write
    }

    @discardableResult
    func switchToSite(withTitle title: String) -> MySiteScreen {
        XCUIApplication().cells[title].tap()
        return MySiteScreen()
    }
}
