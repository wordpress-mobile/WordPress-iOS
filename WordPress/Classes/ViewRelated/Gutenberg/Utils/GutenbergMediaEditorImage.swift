import Foundation
import MediaEditor

/**
 This is a struct to be given to MediaEditor that represent the image.
 We need the full high-quality image in the Media Editor.
 */
class GutenbergMediaEditorImage: AsyncImage {
    private var tasks: [URLSessionDataTask] = []

    private var originalURL: URL

    private var fullQualityURL: URL? {
        guard var urlComponents = URLComponents(url: originalURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        urlComponents.query = nil

        return try? urlComponents.asURL()
    }

    var thumb: UIImage?

    init(url: URL) {
        originalURL = url
        thumb = AnimatedImageCache.shared.cachedStaticImage(url: originalURL)
    }

    /**
     If a thumbnail doesn't exist in cache, fetch one
     */
    func thumbnail(finishedRetrievingThumbnail: @escaping (UIImage?) -> ()) {
        let task = ImageDownloader.shared.downloadImage(at: originalURL, completion: { image, error in
            guard let image = image else {
                finishedRetrievingThumbnail(nil)
                return
            }

            finishedRetrievingThumbnail(image)
        })
        tasks.append(task)
    }

    /**
    Fetch the full high-quality image
    */
    func full(finishedRetrievingFullImage: @escaping (UIImage?) -> ()) {
        let task = ImageDownloader.shared.downloadImage(at: self.fullQualityURL!, completion: { image, error in
            guard let image = image else {
                finishedRetrievingFullImage(nil)
                return
            }

            finishedRetrievingFullImage(image)
        })
        self.tasks.append(task)
    }

    /**
     If the user exits the Media Editor, cancel all requests
     */
    func cancel() {
        tasks.forEach { $0.cancel() }
    }
}
