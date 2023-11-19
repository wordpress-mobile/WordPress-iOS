import Foundation

extension ImageDownloader {

    nonisolated func downloadGravatarImage(with email: String, completion: @escaping (UIImage?) -> Void) {

        guard let url = Gravatar.gravatarUrl(for: email) else {
            completion(nil)
            return
        }

        if let cachedImage = ImageCache.shared.getImage(forKey: url.absoluteString) {
            completion(cachedImage)
            return
        }

        downloadImage(at: url) { image, _ in
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
