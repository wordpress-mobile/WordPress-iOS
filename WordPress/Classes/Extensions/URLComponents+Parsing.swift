import Foundation


// MARK: - URLComponents
//
extension URLComponents {

    /// Attempts to parse the URL contained within a Path, with a given query. Returns nil on failure.
    ///
    static func parseURL(path: String, query: String) -> URL? {
        guard var components = URLComponents(string: path) else {
            return nil
        }

        components.query = query

        return components.url
    }
}
