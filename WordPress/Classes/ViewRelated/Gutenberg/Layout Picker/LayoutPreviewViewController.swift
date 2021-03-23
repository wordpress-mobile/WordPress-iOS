import UIKit

class LayoutPreviewViewController: TemplatePreviewViewController {
    let completion: PageCoordinator.TemplateSelectionCompletion
    let layout: PageTemplateLayout

    init(layout: PageTemplateLayout, selectedPreviewDevice: PreviewDevice?, onDismissWithDeviceSelected: ((PreviewDevice) -> ())?, completion: @escaping PageCoordinator.TemplateSelectionCompletion) {
        self.layout = layout
        self.completion = completion
        super.init(demoURL: layout.demoUrl, selectedPreviewDevice: selectedPreviewDevice, onDismissWithDeviceSelected: onDismissWithDeviceSelected)
        delegate = self
        title = NSLocalizedString("Preview", comment: "Title for screen to preview a static content.")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        primaryActionButton.setTitle(NSLocalizedString("Create Page", comment: "Button for selecting the current page template."), for: .normal)
    }
}

extension LayoutPreviewViewController: TemplatePreviewViewDelegate {
    func deviceButtonTapped(_ previewDevice: PreviewDevice) {
        LayoutPickerAnalyticsEvent.previewModeButtonTapped(previewDevice, layout)
    }

    func deviceModeChanged(_ previewDevice: PreviewDevice) {
        LayoutPickerAnalyticsEvent.previewModeChanged(previewDevice, layout)
    }

    func previewError(_ error: Error) {
        LayoutPickerAnalyticsEvent.previewErrorShown(layout, error)
    }

    func previewViewed() {
        LayoutPickerAnalyticsEvent.previewViewed(selectedPreviewDevice, layout)
    }

    func previewLoading() {
        LayoutPickerAnalyticsEvent.previewLoading(selectedPreviewDevice, layout)
    }

    func previewLoaded() {
        LayoutPickerAnalyticsEvent.previewLoaded(selectedPreviewDevice, layout)
    }

    func templatePicked() {
        LayoutPickerAnalyticsEvent.templateApplied(layout)
        completion(layout)
    }
}
