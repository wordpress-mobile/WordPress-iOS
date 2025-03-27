import Foundation

extension URL {

    /// This methods returns an url that has a scheme for sure unless the original url is an absolute path
    ///
    /// - Returns: an url
    public func normalizedURLForWordPressLink() -> URL {
        let urlString = self.absoluteString

        guard self.scheme == nil,
            !urlString.hasPrefix("/") else {
            return self
        }

        guard let resultURL = URL(string: "http://\(urlString)")  else {
            return self
        }
        return resultURL
    }
}
