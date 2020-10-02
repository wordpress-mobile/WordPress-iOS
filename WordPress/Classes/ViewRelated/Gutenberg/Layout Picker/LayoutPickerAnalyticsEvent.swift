import Foundation

class LayoutPickerAnalyticsEvent {

    static let templateTrackingKey = "template"

    static func templatePreview(slug: String) {
        WPAnalytics.track(.editorSessionTemplatePreview, withProperties: [templateTrackingKey: slug])
    }

    static func templateApplied(slug: String) {
        WPAnalytics.track(.editorSessionTemplateApply, withProperties: [templateTrackingKey: slug])
    }
}
