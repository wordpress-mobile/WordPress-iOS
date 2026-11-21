import Testing

@testable import WordPress

struct RemoveZendeskUserDefaultsTests {

    private let store = InMemoryUserDefaults()

    @Test func removesTheSavedProfileAndUnreadCount() {
        store.set(["email": "user@example.com", "name": "User"], forKey: "wp_zendesk_profile")
        store.set(2, forKey: "wp_zendesk_unread_notifications")

        WordPressAppDelegate.removeZendeskUserDefaults(from: store)

        #expect(store.object(forKey: "wp_zendesk_profile") == nil)
        #expect(store.object(forKey: "wp_zendesk_unread_notifications") == nil)
    }

    @Test func leavesOtherSettingsAlone() {
        store.set(true, forKey: "extra_debug")

        WordPressAppDelegate.removeZendeskUserDefaults(from: store)

        #expect(store.bool(forKey: "extra_debug"))
    }
}
