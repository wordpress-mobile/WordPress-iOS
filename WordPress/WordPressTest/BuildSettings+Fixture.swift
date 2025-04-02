@testable import BuildSettingsKit

extension BuildSettings {

    static func fixture(
        configuration: BuildConfiguration = .debug,
        brand: AppBrand = .wordpress,
        pushNotificationAppID: String = "push-notification-app-id",
        appGroupName: String = "app-group-name",
        appKeychainAccessGroup: String = "app-keychain-access-group",
        eventNamePrefix: String = "event-name-prefix",
        explatPlatform: String = "explat-platform",
        itunesAppID: String = "itunes-app-id",
        appURLScheme: String = "app-url-scheme",
        jetpackAppURLScheme: String = "jetpack-app-url-scheme",
        about: ProductAboutDetails = .fixture(),
        zendeskSourcePlatform: String = "zendesk-source-platform",
        mobileAnnounceAppID: String = "mobile-announce-app-id",
        authKeychainServiceName: String = "auth-keychain-service-name"
    ) -> BuildSettings {
        BuildSettings(
            configuration: configuration,
            brand: brand,
            pushNotificationAppID: pushNotificationAppID,
            appGroupName: appGroupName,
            appKeychainAccessGroup: appKeychainAccessGroup,
            eventNamePrefix: eventNamePrefix,
            explatPlatform: explatPlatform,
            itunesAppID: itunesAppID,
            appURLScheme: appURLScheme,
            jetpackAppURLScheme: jetpackAppURLScheme,
            about: about,
            zendeskSourcePlatform: zendeskSourcePlatform,
            mobileAnnounceAppID: mobileAnnounceAppID,
            authKeychainServiceName: authKeychainServiceName
        )
    }
}

extension BuildSettings.ProductAboutDetails {

    static func fixture(
        twitterHandle: String = "@twitter-handle",
        twitterURL: URL = URL(string: "https://twitter.com/handle")!,
        blogURL: URL = URL(string: "https://wordpress.com/blog")!
    ) -> BuildSettings.ProductAboutDetails {
        BuildSettings.ProductAboutDetails(
            twitterHandle: twitterHandle,
            twitterURL: twitterURL,
            blogURL: blogURL
        )
    }
}
