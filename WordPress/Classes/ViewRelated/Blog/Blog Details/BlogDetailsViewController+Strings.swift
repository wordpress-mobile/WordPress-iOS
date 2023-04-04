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
        )
    }
}

// MARK: - Objective-C Interface

@objc(BlogDetailsViewControllerStrings)
class objc_BlogDetailsViewController_Strings: NSObject {

    @objc class func contentSectionTitle() -> String { BlogDetailsViewController.Strings.contentSectionTitle }
    @objc class func trafficSectionTitle() -> String { BlogDetailsViewController.Strings.trafficSectionTitle }
}
