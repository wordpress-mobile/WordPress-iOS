import UIKit

class LayoutPreviewViewController: TemplatePreviewViewController {
    let completion: PageCoordinator.TemplateSelectionCompletion
    let layout: PageTemplateLayout

    init(layout: PageTemplateLayout, selectedPreviewDevice: PreviewDevice?, onDismissWithDeviceSelected: ((PreviewDevice) -> ())?, completion: @escaping PageCoordinator.TemplateSelectionCompletion) {
        self.layout = layout
        self.completion = completion
        super.init(demoURL: layout.demoUrl, selectedPreviewDevice: selectedPreviewDevice, onDismissWithDeviceSelected: onDismissWithDeviceSelected)
        title = NSLocalizedString("Preview", comment: "Title for screen to preview a static content.")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        primaryActionButton.setTitle(NSLocalizedString("Create Page", comment: "Button for selecting the current page template."), for: .normal)
    }

    override func templatePreviewViewed() {
//        SiteCreationAnalyticsHelper.trackSiteDesignPreviewViewed(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    override func templatePreviewLoading() {
//        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoading(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    override func templatePreviewLoaded() {
//        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoaded(siteDesign: siteDesign, previewMode: selectedPreviewDevice)
    }

    override func templatePicked() {
        LayoutPickerAnalyticsEvent.templateApplied(slug: layout.slug)
        completion(layout)
    }
}
