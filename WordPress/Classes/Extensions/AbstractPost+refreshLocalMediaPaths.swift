import Foundation

extension AbstractPost {
    func refreshLocalMediaPaths() {
        guard isFailed,
            var content = self.content else {
            return
        }

        media.forEach { media in
            guard !media.hasRemote else {
                return
            }

            extractMediaNamesAndPaths(from: media)?.forEach { filename, absolutePath in
                content = content.replacingMatches(of: "src\\s*=\\s*\"(file://.+?/\(NSRegularExpression.escapedPattern(for: filename)))\"", with: "src=\"\(absolutePath)\"")
            }
        }

        self.content = content
    }

    private func extractMediaNamesAndPaths(from media: Media) -> [(String, String)]? {
        var namesAndPaths: [(String, String)] = []

        if let localThumbnailURL = media.localThumbnailURL,
            let absoluteThumbnailLocalURLString = media.absoluteThumbnailLocalURL?.absoluteString {
            namesAndPaths.append((localThumbnailURL, absoluteThumbnailLocalURLString))
        }

        if let localURL = media.localURL,
            let absoluteLocalURLString = media.absoluteLocalURL?.absoluteString {
            namesAndPaths.append((localURL, absoluteLocalURLString))
        }

        return namesAndPaths
    }
}
