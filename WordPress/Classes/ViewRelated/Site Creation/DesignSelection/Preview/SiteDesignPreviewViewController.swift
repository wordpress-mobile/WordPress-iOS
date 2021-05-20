import UIKit

class SiteDesignPreviewViewController: TemplatePreviewViewController {
    let completion: SiteDesignStep.SiteDesignSelection
    let siteDesign: RemoteSiteDesign

    init(siteDesign: RemoteSiteDesign, selectedPreviewDevice: PreviewDevice?, onDismissWithDeviceSelected: ((PreviewDevice) -> ())?, completion: @escaping SiteDesignStep.SiteDesignSelection) {
        self.completion = completion
        self.siteDesign = siteDesign
        super.init(demoURL: siteDesign.demoURL, selectedPreviewDevice: selectedPreviewDevice, onDismissWithDeviceSelected: onDismissWithDeviceSelected)
        delegate = self
        title = NSLocalizedString("Preview", comment: "Title for screen to preview a selected homepage design")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = CollapsableHeaderViewController.closeButton(target: self, action: #selector(closeButtonTapped))
    }
}

extension SiteDesignPreviewViewController: TemplatePreviewViewDelegate {
    func deviceButtonTapped(_ device: PreviewDevice) {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewModeButtonTapped(device)
    }

    func deviceModeChanged(_ device: PreviewDevice) {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewModeChanged(device)
    }

    func previewError(_ error: Error) {
        SiteCreationAnalyticsHelper.trackError(error)
    }

    func previewViewed() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewViewed(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    func previewLoading() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoading(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    func previewLoaded() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoaded(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    func templatePicked() {
        SiteCreationAnalyticsHelper.trackSiteDesignSelected(siteDesign)
        completion(siteDesign)
    }
}
