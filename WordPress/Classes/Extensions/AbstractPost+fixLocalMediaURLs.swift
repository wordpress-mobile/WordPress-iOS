import Foundation

extension AbstractPost {
    /// If a post is in the failed state it can contain references to local files.
    /// When updating the app through the App Store the local paths can change.
    /// This will fix any outdated local path with the correct one.
    ///
    func fixLocalMediaURLs() {
        guard isFailed,
            var content = self.content else {
            return
        }

        media.forEach { media in
            guard !media.hasRemote else {
                return
            }

            filenamesAndAbsolutePaths(from: media).forEach { filename, absolutePath in
                content = content.replacingMatches(of: "src\\s*=\\s*\"(file://.[^\"]+?/\(NSRegularExpression.escapedPattern(for: filename)))\"", with: "src=\"\(absolutePath)\"")
            }
        }

        self.content = content
    }

    private func filenamesAndAbsolutePaths(from media: Media) -> [(filename: String, absolutePath: String)] {
        var filenamesAndAbsolutePaths: [(String, String)] = []

        if let localThumbnailURL = media.localThumbnailURL,
            let absoluteThumbnailLocalURLString = media.absoluteThumbnailLocalURL?.absoluteString {
            filenamesAndAbsolutePaths.append((localThumbnailURL, absoluteThumbnailLocalURLString))
        }

        if let localURL = media.localURL,
            let absoluteLocalURLString = media.absoluteLocalURL?.absoluteString {
            filenamesAndAbsolutePaths.append((localURL, absoluteLocalURLString))
        }

        return filenamesAndAbsolutePaths
    }
}
