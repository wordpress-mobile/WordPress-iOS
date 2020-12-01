import KanvasCamera

class KanvasStoryService: CameraHandlerDelegate {

    let post: Post?
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
        self.post = nil
        cameraHandler.delegate = self
    }

    init(post: Post, updated: @escaping (Result<Post, Error>) -> Void) {
        self.post = post
        self.blog = post.blog
        self.posted = updated
        cameraHandler.delegate = self
    }

    func didCreateMedia(media: [(KanvasCameraMedia?, Error?)]) {
        poster = StoryPoster(context: ContextManager.shared.mainContext)
        let postMedia: [StoryPoster.MediaItem] = media.compactMap { (item, error) in
            guard let item = item else { return nil }
            return StoryPoster.MediaItem(url: item.output, size: item.size, archive: item.archive, original: item.unmodified)
        }

        poster?.post(mediaItems: postMedia, title: "Post from iOS", to: blog, post: self.post) { [weak self] result in
            switch result {
            case .success(let post):
                self?.posted(.success(post))
            case .failure(let error):
                self?.posted(.failure(StoryServiceError.postingError))
            }
        }
    }
}
