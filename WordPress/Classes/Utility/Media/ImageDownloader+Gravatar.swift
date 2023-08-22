import Foundation

extension ImageDownloader {

    func downloadGravatarImage(with email: String, completion: @escaping (UIImage?) -> Void) {

        guard let url = Gravatar.gravatarUrl(for: email) else {
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
}
