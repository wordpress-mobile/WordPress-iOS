import Foundation
import SwiftUI
import Combine

final class SiteSettingsViewModel: ObservableObject {
    private let blog: Blog
    private let service: BlogService
    private var timezoneObserver: TimeZoneObserver?

    @Published private(set) var timezoneLabel: String?
    @Published private(set) var remindersValue: String?

    let onDismissableError = PassthroughSubject<String, Never>()

    init(blog: Blog,
         service: BlogService = BlogService(coreDataStack: ContextManager.shared)) {
        self.blog = blog
        self.service = service
        self.startTimezoneObserver()
        self.remindersValue = makeRemindersValue()
    }

    // MARK: - Refresh

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

    // MARK: - Update

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

    func updateTimezone(_ timezone: WPTimeZone) {
        blog.settings?.gmtOffset = timezone.gmtOffset as NSNumber?
        blog.settings?.timezoneString = timezone.timezoneString
        timezoneLabel = makeTimezoneLabel(for: StoreContainer.shared.timezone.state)
        save()
        trackSettingsChange(fieldName: "timezone", value: timezone.value as Any)
    }

    func didUpdateReminders() {
        remindersValue = makeRemindersValue()
    }

    func save() {
        service.updateSettings(for: blog, success: {
            NotificationCenter.default.post(name: .WPBlogSettingsUpdated, object: nil)
        }, failure: { [weak self] error in
            self?.onDismissableError.send(Strings.saveFailed)
            DDLogError("Error while trying to update BlogSettings: \(error)")
        })
    }

    // MARK: - Helpers (Timezone)

    private func startTimezoneObserver() {
        self.timezoneObserver = TimeZoneObserver { [weak self] _, newState in
            guard let self = self else { return }
            let label = self.makeTimezoneLabel(for: newState)
            guard label != self.timezoneLabel else { return }
            self.timezoneLabel = label
        }
    }

    private func makeTimezoneLabel(for state: TimeZoneStoreState) -> String? {
        guard let settings = blog.settings else {
            return nil
        }
        if let timezone = state.findTimezone(gmtOffset: settings.gmtOffset?.floatValue, timezoneString: settings.timezoneString) {
            return timezone.label
        } else {
            return timezoneValue
        }
    }

    var timezoneValue: String? {
        if let timezoneString = blog.settings?.timezoneString?.nonEmptyString() {
            return timezoneString
        } else if let gmtOffset = blog.settings?.gmtOffset {
            return OffsetTimeZone(offset: gmtOffset.floatValue).label
        } else {
            return nil
        }
    }

    // MARK: - Helpers (Misc)

    private func makeRemindersValue() -> String {
        guard let scheduler = try? ReminderScheduleCoordinator() else {
            return ""
        }
        let formatter = BloggingRemindersScheduleFormatter()
        return formatter.shortScheduleDescription(
            for: scheduler.schedule(for: blog),
            time: scheduler.scheduledTime(for: blog).toLocalTime()
        ).string
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
