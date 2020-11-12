import KanvasCamera

class KanvasStoryService: CameraHandlerDelegate {

    let blog: Blog

    let cameraHandler = KanvasService()
    var poster: StoryPoster?

    let posted: (Result<Post, Error>) -> Void

    enum StoryServiceError: Error {
        case postingError
    }

    init(blog: Blog, posted: @escaping (Result<Post, Error>) -> Void) {
        self.blog = blog
        self.posted = posted
        cameraHandler.delegate = self
    }

    func didCreateMedia(media: [(KanvasCameraMedia?, Error?)]) {
        poster = StoryPoster(context: ContextManager.shared.mainContext)
        let postMedia: [StoryPoster.MediaItem] = media.compactMap { (item, error) in
            switch item {
            case .image(let url, _, let size):
                return StoryPoster.MediaItem(url: url, size: size)
            case .video(let url, _, let size):
                return StoryPoster.MediaItem(url: url, size: size)
            case .frames(let url, _, let size):
                return StoryPoster.MediaItem(url: url, size: size)
            case .none:
                return nil
            }
        }

        if let result = poster?.post(media: postMedia, title: "Post from iOS", to: blog) {
            posted(result)
        } else {
            posted(.failure(StoryServiceError.postingError))
        }
    }
}
