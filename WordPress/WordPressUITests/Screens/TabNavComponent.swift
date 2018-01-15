import Foundation
import XCTest

class TabNavComponent: BaseScreen {

    let meTabButton: XCUIElement

    init() {
        meTabButton = XCUIApplication().tabBars["Main Navigation"].buttons["meTabButton"]
        super.init(element: meTabButton)
    }

    func gotoMeScreen() -> MeTabScreen {
        meTabButton.tap()
        return MeTabScreen.init()
    }

//    Button, 0x600000780000, traits: 8858370049, {{2.0, 619.0}, {71.0, 48.0}}, identifier: 'mySitesTabButton', label: 'My Sites'
//    Button, 0x6000007800d0, traits: 8858370049, {{77.0, 619.0}, {71.0, 48.0}}, identifier: 'readerTabButton', label: 'Reader'
//    Button, 0x6000007801a0, traits: 8858370049, {{152.0, 619.0}, {71.0, 48.0}}, identifier: 'Write', label: 'Write'
//    Button, 0x600000780270, traits: 8858370057, {{227.0, 619.0}, {71.0, 48.0}}, identifier: 'meTabButton', label: 'Me'
//    Button, 0x600000780340, traits: 8858370049, {{302.0, 619.0}, {71.0, 48.0}}, identifier: 'notificationsTabButton', label: 'Notifications'
}
