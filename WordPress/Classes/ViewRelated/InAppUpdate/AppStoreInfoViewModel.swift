import Foundation

struct AppStoreInfoViewModel {
    let appName: String
    let version: String
    let releaseNotes: [String.SubSequence]
    let onUpdateTapped: () -> Void

    init(_ appStoreInfo: AppStoreInfo, onUpdateTapped: @escaping () -> Void) {
        self.appName = appStoreInfo.trackName
        self.version = String(format: Strings.versionFormat, appStoreInfo.version)
        self.releaseNotes = appStoreInfo.releaseNotes.split(whereSeparator: \.isNewline)
        self.onUpdateTapped = onUpdateTapped
    }
}

private enum Strings {
    static let versionFormat = NSLocalizedString("inAppUpdate.appStoreInfo.version", value: "Version %@", comment: "Format for latest version available")
}
