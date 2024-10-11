import Foundation
import WordPressUI
import Gravatar

extension ImageDownloader {

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
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            // Gravatar doesn't support "Cache-Control: none" header. So we add a random query parameter to
            // bypass the backend cache and get the latest image.
            urlComponents?.queryItems?.append(.init(name: "_", value: "\(NSDate().timeIntervalSince1970)"))
            urlToDownload = urlComponents?.url ?? url
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
