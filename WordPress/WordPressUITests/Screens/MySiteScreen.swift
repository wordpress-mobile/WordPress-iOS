import Foundation
import XCTest

private struct ElementStringIDs {
    static let navBarTitle = "My Site"
    static let blogTable = "Blog Details Table"
    static let removeSiteButton = "BlogDetailsRemoveSiteCell"
    static let postsButton = "Blog Post Row"
    static let mediaButton = "Media Row"
    static let statsButton = "Stats Row"
    static let settingsButton = "Settings Row"
    static let createButton = "floatingCreateButton"
    static let ReaderButton = "Reader"
    static let switchSiteButton = "SwitchSiteButton"
    static let addNewSiteButton = "Add new site Button"
}

class MySiteScreen: BaseScreen {
    let tabBar: TabNavComponent
    let removeSiteButton: XCUIElement
    let removeSiteSheet: XCUIElement
    let removeSiteAlert: XCUIElement
    let postsButton: XCUIElement
    let mediaButton: XCUIElement
    let statsButton: XCUIElement
    let siteSettingsButton: XCUIElement
    let createButton: XCUIElement
    let readerButton: XCUIElement
    let switchSiteButton: XCUIElement

    static var isVisible: Bool {
        let app = XCUIApplication()
        let blogTable = app.tables[ElementStringIDs.blogTable]
        return blogTable.exists && blogTable.isHittable
    }

    init() {
        let app = XCUIApplication()
        let blogTable = app.tables[ElementStringIDs.blogTable]
        tabBar = TabNavComponent()
        removeSiteButton = app.cells[ElementStringIDs.removeSiteButton]
        removeSiteSheet = app.sheets.buttons.element(boundBy: 0)
        removeSiteAlert = app.alerts.buttons.element(boundBy: 1)
        postsButton = app.cells[ElementStringIDs.postsButton]
        mediaButton = app.cells[ElementStringIDs.mediaButton]
        statsButton = app.cells[ElementStringIDs.statsButton]
        siteSettingsButton = app.cells[ElementStringIDs.settingsButton]
        createButton = app.buttons[ElementStringIDs.createButton]
        readerButton = app.buttons[ElementStringIDs.ReaderButton]
        switchSiteButton = app.buttons[ElementStringIDs.switchSiteButton]

        super.init(element: XCUIApplication().navigationBars[ElementStringIDs.navBarTitle])
    }

    func showSiteSwitcher() -> MySitesScreen {
        switchSiteButton.tap()
        return MySitesScreen()
    }

    func removeSelfHostedSite() {
        removeSiteButton.tap()
        if isIpad {
            removeSiteAlert.tap()
        } else {
            removeSiteSheet.tap()
        }
    }

    func gotoPostsScreen() -> PostsScreen {
        postsButton.tap()
        return PostsScreen()
    }

    func gotoMediaScreen() -> MediaScreen {
        mediaButton.tap()
        return MediaScreen()
    }

    func gotoStatsScreen() -> StatsScreen {
        statsButton.tap()
        return StatsScreen()
    }

    func gotoSettingsScreen() -> SiteSettingsScreen {
        siteSettingsButton.tap()
        return SiteSettingsScreen()
    }

    func gotoCreateSheet() -> ActionSheetComponent {
        createButton.tap()
        return ActionSheetComponent()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().navigationBars[ElementStringIDs.navBarTitle].exists
    }
}
