import Foundation

class LayoutPickerAnalyticsEvent {
    typealias PreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice

    private static let templateTrackingKey = "template"
    private static let errorTrackingKey = "error"
    private static let previewModeTrackingKey = "preview_mode"

    static func previewErrorShown(_ template: PageTemplateLayout, _ error: Error) {
        WPAnalytics.track(.layoutPickerPreviewErrorShown, withProperties: commonProperties(template, error))
    }

    static func previewLoaded(_ device: PreviewDevice, _ template: PageTemplateLayout) {
        WPAnalytics.track(.layoutPickerPreviewLoaded, withProperties: commonProperties(device, template))
    }

    static func previewLoading(_ device: PreviewDevice, _ template: PageTemplateLayout) {
        WPAnalytics.track(.layoutPickerPreviewLoading, withProperties: commonProperties(device, template))
    }

    static func previewModeButtonTapped(_ device: PreviewDevice, _ template: PageTemplateLayout) {
        WPAnalytics.track(.layoutPickerPreviewModeButtonTapped, withProperties: commonProperties(device, template))
    }

    static func previewModeChanged(_ device: PreviewDevice, _ template: PageTemplateLayout? = nil) {
        WPAnalytics.track(.layoutPickerPreviewModeChanged, withProperties: commonProperties(device, template))
    }

    static func previewViewed(_ device: PreviewDevice, _ template: PageTemplateLayout) {
        WPAnalytics.track(.layoutPickerPreviewViewed, withProperties: commonProperties(device, template))
    }

    static func thumbnailModeButtonTapped(_ device: PreviewDevice) {
        WPAnalytics.track(.layoutPickerThumbnailModeButtonTapped, withProperties: commonProperties(device))
    }

    static func templateApplied(_ template: PageTemplateLayout) {
        WPAnalytics.track(.editorSessionTemplateApply, withProperties: commonProperties(template))
    }

    // MARK: - Common
    private static func commonProperties(_ properties: Any?...) -> [AnyHashable: Any] {
        var result: [AnyHashable: Any] = [:]

        for property: Any? in properties {
            if let template = property as? PageTemplateLayout {
                result.merge([templateTrackingKey: template.slug]) { (_, new) in new }
            }
            if let previewMode = property as? PreviewDevice {
                result.merge([previewModeTrackingKey: previewMode.rawValue]) { (_, new) in new }
            }
            if let error = property as? Error {
                result.merge([errorTrackingKey: error]) { (_, new) in new }
            }
        }

        return result
    }
}
