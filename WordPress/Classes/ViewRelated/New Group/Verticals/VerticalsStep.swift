final class VerticalsStep: WizardStep {
    private let builder: SiteCreator
    private let service: SiteVerticalsService

    var identifier: Identifier {
        return Identifier(value: String(describing: self))
    }

    private(set) lazy var header: UIViewController = {
        let title = NSLocalizedString("What's the focus of your business?", comment: "Create site, step 2. Select focus of the business. Title")
        let subtitle = NSLocalizedString("We'll use your answer to add sections to your website.", comment: "Create site, step 2. Select focus of the business. Subtitle")
        let headerData = SiteCreationHeaderData(title: title, subtitle: subtitle)

        return SiteCreationWizardTitle(data: headerData)
    }()

    private(set) lazy var content: UIViewController = {
        return VerticalsWizardContent(service: self.service)
    }()

    var delegate: WizardDelegate?

    init(builder: SiteCreator, service: SiteVerticalsService) {
        self.builder = builder
        self.service = service
    }
}
