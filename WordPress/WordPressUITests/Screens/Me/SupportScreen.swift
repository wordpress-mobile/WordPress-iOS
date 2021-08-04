import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let closeButton = "close-button"
    static let helpCenter = "help-center-link-button"
    static let contact = "contact-support-button"
    static let myTickets = "my-tickets-button"
    static let contactEmail = "set-contact-email-button"
    static let activityLogs = "activity-logs-button"
    // In Zendesk Views
    static let contactSupportTitle = "Contact us"
    static let myTicketsTitle = "My Tickets"
    static let ZDcancelButton = "ZDKbackButton"
    static let ZDticketsCancelButton = "Cancel"
}

/// This screen object is for the Support section. In the app, it's a modal we can get to from Me 
/// > Help & Support, or, when logged out, from Prologue > tap either continue button > Help.

class SupportScreen: BaseScreen {
    let closeButton: XCUIElement
    let helpCenter: XCUIElement
    let contact: XCUIElement
    let myTickets: XCUIElement
    let contactEmail: XCUIElement
    let activityLogs: XCUIElement
    // In Zendesk Views
    let contactSupportTitle: XCUIElement
    let myTicketsTitle: XCUIElement
    let ZDcancelButton: XCUIElement
    let ZDticketsCancelButton: XCUIElement


    init() {
        let app = XCUIApplication()
        closeButton = app.buttons[ElementStringIDs.closeButton]
        helpCenter = app.cells[ElementStringIDs.helpCenter]
        contact = app.cells[ElementStringIDs.contact]
        myTickets = app.cells[ElementStringIDs.myTickets]
        contactEmail = app.cells[ElementStringIDs.contactEmail]
        activityLogs = app.cells[ElementStringIDs.activityLogs]
        // In Zendesk Views
        contactSupportTitle = app.staticTexts[ElementStringIDs.contactSupportTitle]
        myTicketsTitle = app.staticTexts[ElementStringIDs.myTicketsTitle]
        ZDcancelButton = app.buttons[ElementStringIDs.ZDcancelButton]
        ZDticketsCancelButton = app.buttons[ElementStringIDs.ZDticketsCancelButton]

        super.init(element: activityLogs)

        //Check that each item is loaded:
        XCTAssert(helpCenter.exists)
        XCTAssert(contact.exists)
        XCTAssert(myTickets.exists)
        XCTAssert(contactEmail.exists)
        XCTAssert(activityLogs.exists)
    }

    func dismiss() {
        closeButton.tap()
    }

    func loadContactUs() {
        contact.tap()
        XCTAssert(contactSupportTitle.exists)
        ZDcancelButton.tap()
    }

    func loadMyTickets() {
        myTickets.tap()
        XCTAssert(myTicketsTitle.exists)
        ZDticketsCancelButton.tap()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.activityLogs].exists
    }
}
