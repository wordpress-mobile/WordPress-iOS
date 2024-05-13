import Foundation

struct BlockingUpdateViewModel {
    let appName: String
    let detailsString: String
    let releaseNotes: [String.SubSequence]
    let onUpdateTapped: () -> Void

    init(appStoreInfo: AppStoreInfo, onUpdateTapped: @escaping () -> Void) {
        self.appName = appStoreInfo.trackName
        self.detailsString = makeDetailsString(from: appStoreInfo)
        self.releaseNotes = appStoreInfo.releaseNotes.split(whereSeparator: \.isNewline)
        self.onUpdateTapped = onUpdateTapped
    }
}

private func makeDetailsString(from appStoreInfo: AppStoreInfo) -> String {
    let latestVersion = appStoreInfo.version
    let fileSizeBytes = ByteCountFormatter.string(fromByteCount: Int64(appStoreInfo.fileSizeBytes) ?? 0, countStyle: .file)
    return [latestVersion, fileSizeBytes].joined(separator: " · ")
}
