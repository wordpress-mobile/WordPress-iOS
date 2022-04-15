import Foundation
import UIKit

/// Site Creation: Allows creation of the site's name.
final class SiteNameStep: WizardStep {
    weak var delegate: WizardDelegate?
    private let creator: SiteCreator

    var content: UIViewController {
        weak var weakSelf = self

        return SiteNameViewController(siteNameViewFactory: makeSiteNameView) {
            weakSelf?.didView()
        } onSkip: {
            weakSelf?.didSkip()
        } onCancel: {
            weakSelf?.didCancel()
        }
    }

    init(creator: SiteCreator) {
        self.creator = creator
    }

    func didView() {
        SiteCreationAnalyticsHelper.trackSiteNameViewed()
    }

    func didCancel() {
        SiteCreationAnalyticsHelper.trackSiteNameCanceled()
    }

    func didSkip() {
        SiteCreationAnalyticsHelper.trackSiteNameSkipped()
        didSet(siteName: nil)
    }

    func didSet(siteName: String?) {
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
