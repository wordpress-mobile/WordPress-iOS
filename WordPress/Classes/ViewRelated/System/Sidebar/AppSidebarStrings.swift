import Foundation
import WordPressUI

enum AppSidebarStrings {
    static let manage = NSLocalizedString(
        "sidebar.manage",
        value: "Manage",
        comment: "Sidebar section containing account tools and help"
    )
    static let sectionMySites = NSLocalizedString(
        "sidebar.mySitesSectionTitle",
        value: "Sites",
        comment: "Sidebar section title on iPad"
    )
    static let moreSection = NSLocalizedString(
        "sidebar.moreSectionTitle",
        value: "More",
        comment: "Sidebar section title on iPad"
    )
    static let allSites = NSLocalizedString(
        "sidebar.allSites",
        value: "All Sites",
        comment: "Sidebar button title on iPad"
    )
    static let addSite = NSLocalizedString(
        "sidebar.addSite",
        value: "Add Site",
        comment: "Sidebar button title on iPad"
    )
    static let createSite = NSLocalizedString(
        "sidebar.createSite",
        value: "Create Site",
        comment: "Sidebar button title on iPad"
    )
    static let notifications = NSLocalizedString(
        "sidebar.notifications",
        value: "Notifications",
        comment: "Sidebar item on iPad"
    )
    static let reader = SharedStrings.Reader.title
    static let domains = NSLocalizedString("sidebar.domains", value: "Domains", comment: "Sidebar item on iPad")
    static let help = NSLocalizedString("sidebar.help", value: "Help & Support", comment: "Sidebar item on iPad")
    static let me = NSLocalizedString("sidebar.me", value: "Me", comment: "Sidebar item on iPad")
}
