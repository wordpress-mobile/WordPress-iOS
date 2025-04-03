import Foundation

// MARK: - Swift Interface

extension BlogDetailsViewController {

    enum Strings {
        static let contentSectionTitle = NSLocalizedString(
            "my-site.menu.content.section.title",
            value: "Content",
            comment: "Section title for the content table section in the blog details screen"
        )
        static let trafficSectionTitle = NSLocalizedString(
            "my-site.menu.traffic.section.title",
            value: "Traffic",
            comment: "Section title for the traffic table section in the blog details screen"
        )
        static let maintenanceSectionTitle = NSLocalizedString(
            "my-site.menu.maintenance.section.title",
            value: "Maintenance",
            comment: "Section title for the maintenance table section in the blog details screen"
        )
        static let socialRowTitle = NSLocalizedString(
            "my-site.menu.social.row.title",
            value: "Social",
            comment: "Title for the social row in the blog details screen"
        )
        static let siteMonitoringRowTitle = NSLocalizedString(
            "my-site.menu.site-monitoring.row.title",
            value: "Site Monitoring",
            comment: "Title for the site monitoring row in the blog details screen"
        )
    }
}

// MARK: - Objective-C Interface

@objc(BlogDetailsViewControllerStrings)
public class objc_BlogDetailsViewController_Strings: NSObject {

    @objc public class func contentSectionTitle() -> String { BlogDetailsViewController.Strings.contentSectionTitle }
    @objc public class func trafficSectionTitle() -> String { BlogDetailsViewController.Strings.trafficSectionTitle }
    @objc public class func maintenanceSectionTitle() -> String { BlogDetailsViewController.Strings.maintenanceSectionTitle }
    @objc public class func socialRowTitle() -> String { BlogDetailsViewController.Strings.socialRowTitle }
    @objc public class func siteMonitoringRowTitle() -> String { BlogDetailsViewController.Strings.siteMonitoringRowTitle }
}
