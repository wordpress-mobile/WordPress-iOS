import Foundation

extension AbstractPost {
    func refreshLocalMediaPaths() {
        guard isFailed,
            var content = self.content else {
            return
        }

        let nsContent = content as NSString
        let results = content.matches(regex: "src\\s*=\\s*\"(file://.+?)\"")
        let localURLs = results.map { result in
            return result.range(at: 1).location != NSNotFound
                ? nsContent.substring(with: result.range(at: 1))
                : ""
        }

        localURLs.forEach { localURL in
            guard let url = URL(string: localURL),
                let refreshedUrl = url.refreshLocalPath() else {
                    return
            }

            content = content.replacingOccurrences(of: url.absoluteString, with: refreshedUrl.absoluteString)
        }

        self.content = content
    }
}
