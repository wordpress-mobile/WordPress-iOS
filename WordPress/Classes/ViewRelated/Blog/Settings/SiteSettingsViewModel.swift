import Foundation
import SwiftUI
import Combine

final class SiteSettingsViewModel: ObservableObject {
    private let blog: Blog
    private let service: BlogService

    let onDismissableError = PassthroughSubject<String, Never>()

    init(blog: Blog,
         service: BlogService = BlogService(coreDataStack: ContextManager.shared)) {
        self.blog = blog
        self.service = service
    }

    func refresh() async -> Void {
        await withUnsafeContinuation { continuation in
            service.syncSettings(for: blog, success: {
                continuation.resume()
            }, failure: { error in
                continuation.resume()
                DDLogError("Error while refreshing blog settings: \(error)")
            })
        }
    }

    func updateSiteTitle(_ value: String) {
        guard value != blog.settings?.name else { return }
        blog.settings?.name = value
        save()
        trackSettingsChange(fieldName: "site_title")
    }

    func updateTagline(_ value: String) {
        let tagline = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tagline != blog.settings?.tagline else { return }
        blog.settings?.tagline = tagline
        save()
        trackSettingsChange(fieldName: "tagline")
    }

    func updateVisibility(_ value: SiteVisibility) {
        // The value is already updated by the Binding, just need to save
        save()
        trackSettingsChange(fieldName: "privacy")
    }

    func updateLanguage(_ languageID: NSNumber) {
        guard languageID != blog.settings?.languageID else { return }
        blog.settings?.languageID = languageID
        save()
        trackSettingsChange(fieldName: "language")
    }

    func save() {
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
        static let saveFailed = NSLocalizedString("siteSettings.updateFailedMessage", value: "Settings update failed", comment: "Message to show when setting save failed")
    }
}
