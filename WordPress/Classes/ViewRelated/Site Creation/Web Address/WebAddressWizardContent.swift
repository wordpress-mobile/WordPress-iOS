import UIKit

final class WebAddressWizardContent: DomainSelectionViewController {
    private let siteCreator: SiteCreator

    override var domainPurchasingEnabled: Bool {
        return siteCreator.domainPurchasingEnabled
    }

    override var information: String? {
        return siteCreator.information?.title
    }

    init(creator: SiteCreator, service: SiteAddressService, selection: @escaping (DomainSuggestion) -> Void) {
        self.siteCreator = creator

        super.init(
            service: service,
            domainSelectionType: .purchaseWithPaidPlan,
            primaryActionTitle: creator.domainPurchasingEnabled ? Strings.selectDomain : Strings.createSite,
            selection: selection
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
