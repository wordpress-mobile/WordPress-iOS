import Foundation
import UniformTypeIdentifiers
import WordPressMediaLibrary

extension ExternalRemoteMedia {
    /// Stock Photos: prefer the asset's title (Pexels names are descriptive
    /// and V1 preserves them via `MediaImageExporter(filename:)`). Falls back
    /// to URL basename, then to the localized "External Media" default.
    init(stockPhotosAsset asset: ExternalMediaAsset) {
        self.init(
            url: asset.largeURL,
            suggestedName: Self.normalizeStem(preferred: asset.name, fallback: asset.largeURL),
            contentType: .jpeg,
            caption: asset.caption.isEmpty ? nil : asset.caption
        )
    }

    private static func normalizeStem(preferred: String, fallback: URL) -> String {
        let stem = sanitize(preferred)
        if !stem.isEmpty { return stem }
        let urlStem = sanitize(fallback.deletingPathExtension().lastPathComponent)
        if !urlStem.isEmpty { return urlStem }
        return Strings.defaultExternalMediaStem
    }

    private static func sanitize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped = (trimmed as NSString).deletingPathExtension
        // Treat input composed entirely of path separators as empty so the
        // caller falls through to the URL-basename / localized-default chain.
        let withoutSeparators = stripped.replacingOccurrences(of: "/", with: "")
        if withoutSeparators.isEmpty { return "" }
        return
            stripped
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\0", with: "")
    }
}

private enum Strings {
    static let defaultExternalMediaStem = NSLocalizedString(
        "mediaLibrary.v2.externalMedia.defaultStem",
        value: "External Media",
        comment: "Fallback filename stem when an external picker provides no usable name"
    )
}
