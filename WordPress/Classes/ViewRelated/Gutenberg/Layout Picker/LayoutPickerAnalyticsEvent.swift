import Foundation

class LayoutPickerAnalyticsEvent {

    static let templateTrackingKey = "template"

    static func templatePreview(slug: String) {
        WPAnalytics.track(.editorSessionTemplatePreview, withProperties: [templateTrackingKey: slug])
    }

}
