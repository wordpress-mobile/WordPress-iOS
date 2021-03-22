import UIKit

class SiteDesignPreviewViewController: TemplatePreviewViewController {
    let completion: SiteDesignStep.SiteDesignSelection
    let siteDesign: RemoteSiteDesign

    init(siteDesign: RemoteSiteDesign, selectedPreviewDevice: PreviewDevice?, onDismissWithDeviceSelected: ((PreviewDevice) -> ())?, completion: @escaping SiteDesignStep.SiteDesignSelection) {
        self.completion = completion
        self.siteDesign = siteDesign
        super.init(demoURL: siteDesign.demoURL, selectedPreviewDevice: selectedPreviewDevice, onDismissWithDeviceSelected: onDismissWithDeviceSelected)
        title = NSLocalizedString("Preview", comment: "Title for screen to preview a selected homepage design")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = CollapsableHeaderViewController.closeButton(target: self, action: #selector(closeButtonTapped))
    }

    override func templatePreviewError(_ error: Error) {
        SiteCreationAnalyticsHelper.trackError(error)
    }

    override func templatePreviewViewed() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewViewed(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    override func templatePreviewLoading() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoading(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    override func templatePreviewLoaded() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoaded(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    override func templatePicked() {
        SiteCreationAnalyticsHelper.trackSiteDesignSelected(siteDesign)
        completion(siteDesign)
    }

    override func templatePreviewDeviceButtonTapped(_ device: PreviewDevice) {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewModeButtonTapped(device)
    }

    override func templatePreviewDeviceModeChanged(_ device: PreviewDevice) {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewModeChanged(device)
    }

}
