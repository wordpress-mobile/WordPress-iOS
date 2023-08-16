import Foundation

extension ImageDownloader {

    func downloadGravatarImage(with email: String, completion: @escaping (UIImage?) -> Void) {

        guard let url = gravatarUrl(for: email) else {
            completion(nil)
            return
        }

        downloadImage(at: url) { image, _ in
            DispatchQueue.main.async {

                guard let image else {
                    completion(nil)
                    return
                }

                completion(image)
            }
        }
    }

    private func gravatarUrl(for email: String) -> URL? {
        let baseURL = "https://gravatar.com/avatar"
        let hash = gravatarHash(of: email)
        let size = 80
        let targetURL = String(format: "%@/%@?d=404&s=%d&r=g", baseURL, hash, size)
        return URL(string: targetURL)
    }

    private func gravatarHash(of email: String) -> String {
        return email
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .md5Hash()
    }
}
