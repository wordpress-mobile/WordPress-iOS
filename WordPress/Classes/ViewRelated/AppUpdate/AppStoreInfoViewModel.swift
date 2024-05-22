import Foundation

struct AppStoreInfoViewModel {
    let appName: String
    let version: String
    let releaseNotes: [String.SubSequence]

    let title = Strings.title
    let message = Strings.message
    let whatsNewTitle = Strings.whatsNew
    let updateButtonTitle = Strings.Actions.update
    let latestVersionButtonTitle = Strings.Actions.latestVersion
    let cancelButtonTitle = Strings.Actions.cancel

    init(_ appStoreInfo: AppStoreLookupResponse.AppStoreInfo) {
        self.appName = appStoreInfo.trackName
        self.version = String(format: Strings.versionFormat, appStoreInfo.version)
        self.releaseNotes = appStoreInfo.releaseNotes.split(whereSeparator: \.isNewline)
    }
}

private enum Strings {
    static let versionFormat = NSLocalizedString("appUpdate.versionFormat", value: "Version %@", comment: "Format for latest version available")
    static let title = NSLocalizedString("appUpdate.title", value: "App Update Available", comment: "Title for view displayed when there's a newer version of the app available")
    static let message = NSLocalizedString("appUpdate.message", value: "To use this app, download the latest version.", comment: "Message for view displayed when there's a newer version of the app available")
    static let whatsNew = NSLocalizedString("appUpdate.whatsNew", value: "What's New", comment: "Section title for what's new in the latest update available")

    enum Actions {
        static let update = NSLocalizedString("appUpdate.action.update", value: "Update", comment: "Update button title")
        static let latestVersion = NSLocalizedString("appUpdate.action.latestVersion", value: "Get the latest version", comment: "Get the latest version button title")
        static let cancel = NSLocalizedString("appUpdate.action.cancel", value: "Cancel", comment: "Cancel button title")
    }
}
