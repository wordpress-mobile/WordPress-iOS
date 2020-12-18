import KanvasCamera

class KanvasStoryService: CameraHandlerDelegate {

    typealias Output = (Post, [Media])

    let post: Post?
    let blog: Blog

    let cameraHandler = KanvasService()
    var poster: StoryPoster?

    let posted: (Result<Output, Error>) -> Void
    let uploaded: (Result<Output, Error>) -> Void

    enum StoryServiceError: Error {
        case postingError
    }

    init(blog: Blog, posted: @escaping (Result<Output, Error>) -> Void, uploaded: @escaping (Result<Output, Error>) -> Void) {
        self.blog = blog
        self.posted = posted
        self.uploaded = uploaded
        self.post = nil
        cameraHandler.delegate = self
    }

    init(post: Post, updated: @escaping (Result<Output, Error>) -> Void, uploaded: @escaping (Result<Output, Error>) -> Void) {
        self.post = post
        self.blog = post.blog
        self.posted = updated
        self.uploaded = uploaded
        cameraHandler.delegate = self
    }

    func didCreateMedia(media: [(KanvasCameraMedia?, Error?)]) {
        poster = StoryPoster(context: blog.managedObjectContext ?? ContextManager.shared.mainContext)
        let postMedia: [StoryPoster.MediaItem] = media.compactMap { (item, error) in
            guard let item = item else { return nil }
            return StoryPoster.MediaItem(url: item.output, size: item.size, archive: item.archive, original: item.unmodified)
        }

        poster?.post(mediaItems: postMedia, title: "Post from iOS", to: blog, post: self.post) { [weak self] result in
            switch result {
            case .success(let post):
                guard let self = self else { return }
                let media = self.poster?.upload(mediaItems: postMedia, post: self.post!, completion: self.uploaded)
                if let media = media {
                    self.posted(.success((post, media)))
                }
//                self?.poster?.upload(mediaItems: postMedia, post: post, completion: { uploadResult in

//                })
            case .failure(let error):
                self?.posted(.failure(StoryServiceError.postingError))
            }
        }
    }
}
