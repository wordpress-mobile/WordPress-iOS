import Foundation
import WordPressUI
import Gravatar

extension ImageDownloader {

    static func downloadGravatarImage(with email: String, completion: @escaping (UIImage?) -> Void) {

        let options: ImageDownloadOptions = .init(defaultAvatarOption: .status404)

        guard let avatarURL = AvatarURL(with: .email(email), options: options.avatarQueryOptions) else {
            completion(nil)
            return
        }

        if let cachedImage = ImageCache.shared.getImage(forKey: avatarURL.url.absoluteString) {
            completion(cachedImage)
            return
        }

        guard let gravatarCache = WordPressUI.ImageCache.shared as? GravatarImageCaching else {
            assertionFailure("WordPressUI.ImageCache.shared should conform to GravatarImageCaching.")
            completion(nil)
            return
        }

        let avatarService = Gravatar.AvatarService(cache: gravatarCache)
        Task {
            do {
                let result = try await avatarService.fetch(with: .email(email), options: options)
                await MainActor.run {
                    completion(result.image)
                }
            } catch {
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
}
