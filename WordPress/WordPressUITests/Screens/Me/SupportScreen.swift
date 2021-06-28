import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let helpCenter = "WordPress Help Center"
    static let contact = "Contact Support"
    static let myTickets = "My Tickets"
    static let contactEmail = "Contact Email"
    static let activityLogs = "Activity Logs"
}

class SupportScreen: BaseScreen {
    let helpCenter: XCUIElement
    let contact: XCUIElement
    let myTickets: XCUIElement
    let contactEmail: XCUIElement
    let activityLogs: XCUIElement

    init() {
        let app = XCUIApplication()
        helpCenter = app.buttons[ElementStringIDs.helpCenter]
        contact = app.buttons[ElementStringIDs.contact]
        myTickets = app.buttons[ElementStringIDs.myTickets]
        contactEmail = app.buttons[ElementStringIDs.contactEmail]
        activityLogs = app.buttons[ElementStringIDs.activityLogs]

        super.init(element: activityLogs)
    }
}
