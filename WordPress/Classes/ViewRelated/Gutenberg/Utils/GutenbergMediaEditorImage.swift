import Foundation
import MediaEditor

/**
 This is a struct to be given to MediaEditor that represent the image.
 We need the full high-quality image in the Media Editor.
 */
class GutenbergMediaEditorImage: AsyncImage {
    private var tasks: [ImageDownloaderTask] = []

    private var originalURL: URL

    private let post: AbstractPost

    private var fullQualityURL: URL? {
        guard var urlComponents = URLComponents(url: originalURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        urlComponents.query = nil

        return try? urlComponents.asURL()
    }

    private lazy var mediaUtility: EditorMediaUtility = {
        return EditorMediaUtility()
    }()

    var thumb: UIImage?

    init(url: URL, post: AbstractPost) {
        originalURL = url
        self.post = post
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
        // By passing .zero as the size the full quality image will be downloaded
        let task = mediaUtility.downloadImage(from: fullQualityURL!, size: .zero, scale: .greatestFiniteMagnitude, post: post, success: { image in
            finishedRetrievingFullImage(image)
        }, onFailure: { _ in
            finishedRetrievingFullImage(nil)
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
