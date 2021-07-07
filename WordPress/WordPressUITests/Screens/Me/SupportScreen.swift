import UITestsFoundation
import XCTest

// This screen object is for the Support section. In the app, it's a modal we can get to from Me > Help & Support, or, when logged out, from Prologue > tap either continue button > Help.

private struct ElementStringIDs {
    static let closeButton = "close-button"
    static let helpCenter = "help-center-link-button"
    static let contact = "contact-support-button"
    static let myTickets = "my-tickets-button"
    static let contactEmail = "set-contact-email-button"
    static let activityLogs = "activity-logs-button"
}

class SupportScreen: BaseScreen {
    let closeButton: XCUIElement
    let helpCenter: XCUIElement
    let contact: XCUIElement
    let myTickets: XCUIElement
    let contactEmail: XCUIElement
    let activityLogs: XCUIElement

    init() {
        let app = XCUIApplication()
        closeButton = app.buttons[ElementStringIDs.closeButton]
        helpCenter = app.cells[ElementStringIDs.helpCenter]
        contact = app.cells[ElementStringIDs.contact]
        myTickets = app.cells[ElementStringIDs.myTickets]
        contactEmail = app.cells[ElementStringIDs.contactEmail]
        activityLogs = app.cells[ElementStringIDs.activityLogs]

        super.init(element: activityLogs)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.activityLogs].exists
    }
}
