/// Site Creation. Second screen: Site Verticals
final class WebAddressStep: WizardStep {
    private let creator: SiteCreator

    private(set) lazy var header: UIViewController = {
        let title = NSLocalizedString("Lastly, choose and address for your site", comment: "Create site, step 3. Select address for the site. Title")
        let subtitle = NSLocalizedString("A domain name is your main site address", comment: "Create site, step 3. Select address for the site. Subtitle")
        let headerData = SiteCreationHeaderData(title: title, subtitle: subtitle)

        return SiteCreationWizardTitle(data: headerData)
    }()

    private(set) lazy var content: UIViewController = {
        return UIViewController()
    }()

    var delegate: WizardDelegate?

    init(creator: SiteCreator) {
        self.creator = creator
    }
}
