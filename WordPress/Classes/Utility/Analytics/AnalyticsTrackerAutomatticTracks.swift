import Foundation
import AutomatticTracks
import WordPressShared
import BuildSettingsKit

@objc public final class AnalyticsTrackerAutomatticTracks: NSObject, WPAnalyticsTracker {
    private let contextManager: TracksContextManager
    private let tracksService: TracksService
    private var userProperties: [String: Any] = [:]
    private var appURLScheme: String
    private var cachedAnonymousUserID: String?
    private var cachedCurrentUserID: String?

    @objc convenience public override init() {
        let settings = BuildSettings.current
        self.init(
            eventNamePrefix: WPAnalyticsTesting.eventNamePrefix ?? settings.eventNamePrefix,
            platform: WPAnalyticsTesting.explatPlatform ?? settings.explatPlatform,
            appURLScheme: settings.appURLScheme
        )
    }

    init(
        eventNamePrefix: String,
        platform: String,
        appURLScheme: String
    ) {
        contextManager = TracksContextManager()
        tracksService = TracksService(contextManager: contextManager)
        tracksService.eventNamePrefix = eventNamePrefix
        tracksService.platform = platform
        self.appURLScheme = appURLScheme
    }

    // MARK: - WPAnalyticsTracker

    public func track(_ stat: WPAnalyticsStat) {
        track(stat, withProperties: nil)
    }

    public func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        guard let event = TracksMappedEvent.make(for: stat) else {
            DDLogInfo("WPAnalyticsStat not supported by AnalyticsTrackerAutomatticTracks: \(stat)")
            return
        }

        let properties = (event.properties ?? [:])
            .merging(properties ?? [:]) { _, new in new }
        trackString(event.name, withProperties: properties)
    }

    public func trackString(_ event: String) {
        trackString(event, withProperties: nil)
    }

    public func trackString(_ event: String, withProperties properties: [AnyHashable: Any]?) {
        if properties == nil {
            DDLogInfo("🔵 Tracked: \(event)")
        } else {
            let description = (properties ?? [:])
                .map { (key: "\($0)", value: $1) }
                .sorted {
                    $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
                }
                .map { key, value in "\(key): \(value)" }
                .joined(separator: ", ")
            DDLogInfo("🔵 Tracked: \(event) <\(description)>")
        }
        tracksService.trackEventName(event, withCustomProperties: properties)
    }

    // MARK: - Session Management

    @objc public func beginSession() {
        if let currentUserID, !currentUserID.isEmpty {
            tracksService.switchToAuthenticatedUser(
                withUsername: currentUserID,
                userID: nil,
                wpComToken: try? WPAccount.token(forUsername: currentUserID),
                skipAliasEventCreation: true
            )
        } else {
            tracksService.switchToAnonymousUser(withAnonymousID: anonymousUserID)
        }
        refreshMetadata()
    }

    @objc public func clearQueuedEvents() {
        tracksService.clearQueuedEvents()
    }

    @objc public func refreshMetadata() {
        let session = getSessionInfo(in: ContextManager.shared.mainContext)

        if let username = session.username, UUID(uuidString: username) != nil {
            // User has authenticated but we're waiting for account details to sync.
            // Once details are synced this method will be called again with the actual
            // username. For now just exit without making changes.
            return
        }

        let userProperties = makeUserProperties(with: session)
        tracksService.userProperties.removeAllObjects()
        tracksService.userProperties.addEntries(from: userProperties)

        startTracksSession(with: session)
    }

    private func startTracksSession(with session: SessionInfo) {
        guard session.isDotcomUser, let username = session.username else {
            // User is not authenticated, switch to an anonymous mode
            tracksService.switchToAnonymousUser(withAnonymousID: anonymousUserID)
            currentUserID = nil
            return
        }

        if (currentUserID ?? "").isEmpty {
            // No previous username logged
            currentUserID = username
            removeAnonymousID()

            tracksService.switchToAuthenticatedUser(
                withUsername: username,
                userID: "",
                wpComToken: try? WPAccount.token(forUsername: username),
                skipAliasEventCreation: false
            )
        } else if currentUserID == username {
            // Username did not change from last refreshMetadata - just make sure Tracks client has it
            tracksService.switchToAuthenticatedUser(
                withUsername: username,
                userID: "",
                wpComToken: try? WPAccount.token(forUsername: username),
                skipAliasEventCreation: true
            )
        } else {
            // Username changed for some reason - switch back to anonymous first
            tracksService.switchToAnonymousUser(withAnonymousID: anonymousUserID)
            tracksService.switchToAuthenticatedUser(
                withUsername: username,
                userID: "",
                wpComToken: try? WPAccount.token(forUsername: username),
                skipAliasEventCreation: false
            )
            currentUserID = username
            removeAnonymousID()
        }
    }

    // MARK: - SessionInfo

    private struct SessionInfo {
        var blogCount: Int
        var username: String?
        var isDotcomUser: Bool
        var hasJetpackBlogs: Bool
        var isGutenbergEnabled: Bool
    }

    private func getSessionInfo(in context: NSManagedObjectContext) -> SessionInfo {
        context.performAndWait {
            let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
            return SessionInfo(
                blogCount: Blog.count(in: context),
                username: account?.username,
                isDotcomUser: account?.username.isEmpty == false,
                hasJetpackBlogs: (try? Blog.hasAnyJetpackBlogs(in: context)) == true,
                isGutenbergEnabled: (account?.blogs ?? []).contains(where: \.isGutenbergEnabled)
            )
        }
    }

    private func makeUserProperties(with info: SessionInfo) -> [String: Any] {
        return [
            "app_scheme": WPAnalyticsTesting.appURLScheme ?? appURLScheme,
            "platform": "iOS",
            "dotcom_user": info.isDotcomUser,
            "jetpack_user": info.hasJetpackBlogs,
            "number_of_blogs": info.blogCount,
            "accessibility_voice_over_enabled": UIAccessibility.isVoiceOverRunning,
            "is_rtl_language": UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft,
            "gutenberg_enabled": info.isGutenbergEnabled,
        ]
    }

    // MARK: - Private

    private var anonymousUserID: String {
        if cachedAnonymousUserID == nil || cachedAnonymousUserID?.isEmpty == true {
            let userDefaults = UserPersistentStoreFactory.instance()
            var anonymousID = userDefaults.string(forKey: Constants.tracksUserDefaultsAnonymousUserIDKey)

            if anonymousID == nil {
                anonymousID = UUID().uuidString
                userDefaults.set(anonymousID, forKey: Constants.tracksUserDefaultsAnonymousUserIDKey)
            }

            cachedAnonymousUserID = anonymousID
        }

        return cachedAnonymousUserID!
    }

    private func removeAnonymousID() {
        cachedAnonymousUserID = nil
        UserPersistentStoreFactory.instance()
            .removeObject(forKey: Constants.tracksUserDefaultsAnonymousUserIDKey)
    }

    private var currentUserID: String? {
        get {
            if cachedCurrentUserID == nil || cachedCurrentUserID?.isEmpty == true {
                let userDefaults = UserPersistentStoreFactory.instance()
                let loggedInID = userDefaults.string(forKey: Constants.tracksUserDefaultsLoggedInUserIDKey)

                if loggedInID != nil {
                    cachedCurrentUserID = loggedInID
                }
            }

            return cachedCurrentUserID
        }
        set {
            cachedCurrentUserID = newValue

            let userDefaults = UserPersistentStoreFactory.instance()
            if let newValue {
                userDefaults.set(newValue, forKey: Constants.tracksUserDefaultsLoggedInUserIDKey)
            } else {
                userDefaults.removeObject(forKey: Constants.tracksUserDefaultsLoggedInUserIDKey)
            }
        }
    }
}

private enum Constants {
    static let tracksUserDefaultsAnonymousUserIDKey = "TracksAnonymousUserID"
    static let tracksUserDefaultsLoggedInUserIDKey = "TracksLoggedInUserID"
}
