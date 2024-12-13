import Foundation
import WordPressMedia

extension ImageDownloader {
    static let shared = ImageDownloader(authenticator: MediaRequestAuthenticator())
}
