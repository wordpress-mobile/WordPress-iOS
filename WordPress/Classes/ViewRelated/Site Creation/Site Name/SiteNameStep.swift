import Foundation
import UIKit

/// Site Creation: Allows creation of the site's name.
final class SiteNameStep: WizardStep {
    weak var delegate: WizardDelegate?
    private let creator: SiteCreator

    var content: UIViewController {
        SiteNameViewController(siteNameViewFactory: makeSiteNameView) { [weak self] in
            SiteCreationAnalyticsHelper.trackSiteNameSkipped()
            self?.didSet(siteName: nil)
        }
    }

    init(creator: SiteCreator) {
        self.creator = creator
    }

    private func didSet(siteName: String?) {
        if let siteName = siteName {
            SiteCreationAnalyticsHelper.trackSiteNameEntered(siteName)
        }

        // if users go back and then skip, the failable initializer of SiteInformation
        // will reset the state, avoiding to retain the previous site name
        creator.information = SiteInformation(title: siteName, tagLine: creator.information?.tagLine)
        delegate?.nextStep()
    }
}

// Site Name View Factory
extension SiteNameStep {
    /// Builds a the view to be used as main content
    private func makeSiteNameView() -> UIView {
        SiteNameView(siteVerticalName: creator.vertical?.localizedTitle ?? "") { [weak self] siteName in
            self?.didSet(siteName: siteName?.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
