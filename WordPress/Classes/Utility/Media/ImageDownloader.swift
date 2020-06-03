import Foundation

// MARK: - ImageDownloadTask protocol

/// This protocol can be implemented to represent an image download task handled by the ImageDownloader.
///
protocol ImageDownloaderTask {
    /// Calling this method should cancel the task's execution.
    ///
    func cancel()
}

extension Operation: ImageDownloaderTask {}
extension URLSessionTask: ImageDownloaderTask {}

extension URLSession: ImageDownloaderTask {
    func cancel() {
        invalidateAndCancel()
    }
}

// MARK: - Image Downloading Tool

class ImageDownloader {

    /// Shared Instance!
    ///
    static let shared = ImageDownloader()

    /// Internal URLSession Instance
    ///
    private let session = URLSession(configuration: .default)


    deinit {
        session.invalidateAndCancel()
    }


    /// Downloads the UIImage resource at the specified URL. On completion the received closure will be executed.
    ///
    @discardableResult
    func downloadImage(at url: URL, completion: @escaping (UIImage?, Error?) -> Void) -> ImageDownloaderTask {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        return downloadImage(for: request, completion: completion)
    }

    /// Downloads the UIImage resource at the specified endpoint. On completion the received closure will be executed.
    ///
    @discardableResult
    func downloadImage(for request: URLRequest, completion: @escaping (UIImage?, Error?) -> Void) -> ImageDownloaderTask {
        let task = session.dataTask(with: request) { (data, _, error) in
            guard let data = data else {
              completion(nil, ImageDownloaderError.failed)
              return
            }
            var image: UIImage?
            if let url = request.url, url.pathExtension.lowercased() == "gif" {
              image = RCTAnimatedImage(data: data, scale:1)
            } else {
              image = UIImage.init(data: data)
            }
            if let finalImage = image {
              completion(finalImage, nil)
            } else {
              completion(nil, ImageDownloaderError.failed)
            }
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
