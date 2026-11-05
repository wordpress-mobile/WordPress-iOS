import UIKit
import WordPressKit

class SiteDesignPreviewViewController: TemplatePreviewViewController {
    private let context: SiteDesignPickerContext
    let completion: SiteDesignStep.SiteDesignSelection
    let siteDesign: RemoteSiteDesign
    let sectionType: SiteDesignSectionType

    init(siteDesign: RemoteSiteDesign,
         selectedPreviewDevice: PreviewDevice?,
         context: SiteDesignPickerContext,
         sectionType: SiteDesignSectionType,
         onDismissWithDeviceSelected: ((PreviewDevice) -> ())?,
         completion: @escaping SiteDesignStep.SiteDesignSelection) {

        self.completion = completion
        self.siteDesign = siteDesign
        self.context = context
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
        navigationItem.leftBarButtonItem = UIBarButtonItem.makeCloseButton(
            target: self,
            action: #selector(closeButtonTapped)
        )
        setPrimaryActionButtonTitle()
    }

    private func setPrimaryActionButtonTitle() {
        let title: String
        switch context {
        case .siteCreation(let createsSite):
            title = createsSite ? TextContent.createSiteButton : TextContent.chooseButton
        case .dashboard:
            title = TextContent.applyButton
        }
        primaryActionButton.setTitle(title, for: .normal)
    }

    private enum TextContent {
        static let previewTitle = NSLocalizedString("Preview", comment: "Title for screen to preview a selected homepage design.")
        static let createSiteButton = NSLocalizedString("Create Site", comment: "Title for the button to progress with creating the site with the selected design.")
        static let chooseButton = NSLocalizedString("Choose", comment: "Title for the button to progress with the selected site homepage design.")
        static let applyButton = NSLocalizedString(
            "siteDesignPreview.applyButton",
            value: "Apply",
            comment: "Title for the button that applies the previewed design to an existing site."
        )
    }
}

extension SiteDesignPreviewViewController: TemplatePreviewViewDelegate {
    func deviceButtonTapped(_ device: PreviewDevice) {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewModeButtonTapped(device, source: context.analyticsSource)
    }

    func deviceModeChanged(_ device: PreviewDevice) {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewModeChanged(device, source: context.analyticsSource)
    }

    func previewError(_ error: Error) {
        SiteCreationAnalyticsHelper.trackError(error)
    }

    func previewViewed() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewViewed(
            siteDesign: siteDesign,
            previewMode: selectedPreviewDevice,
            source: context.analyticsSource
        )
    }

    func previewLoading() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoading(
            siteDesign: siteDesign,
            previewMode: selectedPreviewDevice,
            source: context.analyticsSource
        )
    }

    func previewLoaded() {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoaded(
            siteDesign: siteDesign,
            previewMode: selectedPreviewDevice,
            source: context.analyticsSource
        )
    }

    func templatePicked() {
        SiteCreationAnalyticsHelper.trackSiteDesignSelected(
            siteDesign,
            sectionType: sectionType,
            source: context.analyticsSource
        )
        completion(siteDesign)
    }
}
