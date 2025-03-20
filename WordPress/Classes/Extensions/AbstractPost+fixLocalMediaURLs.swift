import Foundation
import WordPressShared

extension AbstractPost {
    /// When updating the app through the App Store or installing a new version
    /// of the app from Xcode, the local paths can change. This will fix any
    /// outdated local path with the correct one.
    func fixLocalMediaURLs() {
        guard var content = self.content else { return }

        media.forEach { media in
            guard !media.hasRemote else {
                return
            }

            /// It would be better to use HTMLProcessor here. But since this is an entity
            /// from Aztec we decided to use a REGEX to have an editor-agnostic solution.
            ///
            filenamesAndAbsolutePaths(from: media).forEach { filename, absolutePath in
                content = content.replacingMatches(of: regexOfHTMLSourceContaining(localFilename: filename), with: "src=\"\(absolutePath)\"")
            }
        }

        self.content = content
    }

    private func regexOfHTMLSourceContaining(localFilename: String) -> String {
        return "src\\s*=\\s*\"(file://.[^\"]+?/\(NSRegularExpression.escapedPattern(for: localFilename)))\""
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
