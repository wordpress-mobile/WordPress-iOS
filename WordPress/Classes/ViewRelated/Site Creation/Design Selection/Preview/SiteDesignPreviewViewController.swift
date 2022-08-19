import UIKit

class SiteDesignPreviewViewController: TemplatePreviewViewController {
    private let createsSite: Bool
    let completion: SiteDesignStep.SiteDesignSelection
    let siteDesign: RemoteSiteDesign
    let sectionType: SiteDesignSectionType

    init(siteDesign: RemoteSiteDesign,
         selectedPreviewDevice: PreviewDevice?,
         createsSite: Bool,
         sectionType: SiteDesignSectionType,
         onDismissWithDeviceSelected: ((PreviewDevice) -> ())?,
         completion: @escaping SiteDesignStep.SiteDesignSelection) {

        self.completion = completion
        self.siteDesign = siteDesign
        self.createsSite = createsSite
        self.sectionType = sectionType
        super.init(demoURL: siteDesign.demoURL, selectedPreviewDevice: selectedPreviewDevice, onDismissWithDeviceSelected: onDismissWithDeviceSelected)
        delegate = self
        title = TextContent.previewTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = CollapsableHeaderViewController.closeButton(target: self, action: #selector(closeButtonTapped))
        setPrimaryActionButtonTitle()
    }

    private func setPrimaryActionButtonTitle() {
        primaryActionButton.setTitle(createsSite ? TextContent.createSiteButton : TextContent.chooseButton, for: .normal)
    }

    private enum TextContent {
        static let previewTitle = NSLocalizedString("Preview", comment: "Title for screen to preview a selected homepage design.")
        static let createSiteButton = NSLocalizedString("Create Site", comment: "Title for the button to progress with creating the site with the selected design.")
        static let chooseButton = NSLocalizedString("Choose", comment: "Title for the button to progress with the selected site homepage design.")
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
        SiteCreationAnalyticsHelper.trackSiteDesignSelected(siteDesign, sectionType: sectionType)
        completion(siteDesign)
    }
}
