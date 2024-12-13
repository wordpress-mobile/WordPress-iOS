import Foundation
import WordPressUI
import Gravatar
import WordPressMedia

extension WordPressMedia.ImageDownloader {

    nonisolated func downloadGravatarImage(with email: String, forceRefresh: Bool = false, completion: @escaping (UIImage?) -> Void) {

        guard let url = AvatarURL.url(for: email) else {
            completion(nil)
            return
        }

        if !forceRefresh, let cachedImage = ImageCache.shared.getImage(forKey: url.absoluteString) {
            completion(cachedImage)
            return
        }
        var urlToDownload = url
        if forceRefresh {
            urlToDownload = url.appendingGravatarCacheBusterParam()
        }
        downloadImage(at: urlToDownload) { image, _ in
            DispatchQueue.main.async {

                guard let image else {
                    completion(nil)
                    return
                }

                ImageCache.shared.setImage(image, forKey: url.absoluteString)
                completion(image)
            }
        }
    }
}
