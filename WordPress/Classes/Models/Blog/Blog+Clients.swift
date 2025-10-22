import Foundation
import WordPressCore
import WordPressData

extension Blog {

    /// This function is expensive – prefer passing the `WordPressClient` from the top of the navigation heirarchy instead.
    ///
    /// This function tries to re-use `WordPressClient` objects where possible to retain cached data.
    ///
    func wordPressClient() -> WordPressClient? {
        guard let site = try? WordPressSite(blog: self) else {
            return nil
        }

        return WordPressClient.for(site: site)
    }
}
