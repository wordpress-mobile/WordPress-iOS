@testable import WordPressKit // Announcement is defined here

extension Announcement {

    static func fixture(
        minimumAppVersion: String = "1.0",
        maximumAppVersion: String = "2.0",
        appVersionTargets: [String] = []
    ) -> Announcement {
        Announcement(
            appVersionName: "0.0",
            minimumAppVersion: minimumAppVersion,
            maximumAppVersion: maximumAppVersion,
            appVersionTargets: appVersionTargets,
            detailsUrl: "http://wordpress.org",
            announcementVersion: "1.0",
            isLocalized: false,
            responseLocale: "",
            features: []
        )
    }
}
