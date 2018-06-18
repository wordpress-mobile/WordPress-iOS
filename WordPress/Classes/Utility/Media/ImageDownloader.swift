import Foundation


// MARK: - Image Downloading Tool
//
class ImageDownloader {

    /// Shared Instance!
    ///
    static let shared = ImageDownloader()

    /// Public Aliases
    ///
    typealias Task = URLSessionDataTask

    /// Internal URLSession Instance
    ///
    private let session = URLSession(configuration: .default)


    deinit {
        session.invalidateAndCancel()
    }


    /// Downloads the UIImage resource at the specified URL. On completion the received closure will be executed.
    ///
    @discardableResult
    func downloadImage(at url: URL, completion: @escaping (UIImage?, Error?) -> Void) -> Task {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        return downloadImage(for: request, completion: completion)
    }

    /// Downloads the UIImage resource at the specified endpoint. On completion the received closure will be executed.
    ///
    @discardableResult
    func downloadImage(for request: URLRequest, completion: @escaping (UIImage?, Error?) -> Void) -> Task {
        let task = session.dataTask(with: request) { (data, _, error) in
            guard let data = data, let image = UIImage(data: data) else {
                let error = error ?? ImageDownloaderError.failed
                completion(nil, error)
                return
            }

            completion(image, nil)
        }

        task.resume()
        return task
    }
}


// MARK: - Error Types
//
enum ImageDownloaderError: Error {
    case failed
}
