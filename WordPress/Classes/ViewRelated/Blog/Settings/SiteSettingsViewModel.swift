import Foundation
import SwiftUI
import Combine

final class SiteSettingsViewModel: ObservableObject {
    private let blog: Blog
    private let service: BlogService

    let onDismissableError = PassthroughSubject<String, Never>()

    init(blog: Blog) {
        self.blog = blog
        self.service = BlogService(coreDataStack: ContextManager.shared)
    }

    func updateSiteTitle(_ value: String) {
        guard value != blog.settings?.name else { return }
        blog.settings?.name = value
        save()
        trackSettingsChange(fieldName: "site_title")
    }

    private func save() {
        service.updateSettings(for: blog, success: {
            NotificationCenter.default.post(name: .WPBlogSettingsUpdated, object: nil)
        }, failure: { [weak self] error in
            self?.onDismissableError.send(Strings.saveFailed)
            DDLogError("Error while trying to update BlogSettings: \(error)")
        })
    }

    private func trackSettingsChange(fieldName: String, value: Any? = nil) {
        WPAnalytics.trackSettingsChange("site_settings", fieldName: fieldName, value: value)
    }
}

private extension SiteSettingsViewModel {
    enum Strings {
        static let saveFailed = NSLocalizedString("Settings update failed", comment: "Message to show when setting save failed")
    }
}
