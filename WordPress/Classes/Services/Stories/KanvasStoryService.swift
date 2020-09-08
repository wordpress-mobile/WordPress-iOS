import Kanvas

class KanvasStoryService: CameraHandlerDelegate {

    let blog: Blog

    let cameraHandler = KanvasService()
    var poster: StoryPoster?

    let posted: (Result<Post, Error>) -> Void

    init(blog: Blog, posted: @escaping (Result<Post, Error>) -> Void) {
        self.blog = blog
        self.posted = posted
        cameraHandler.delegate = self
    }

    func didCreateMedia(media: [(KanvasCameraMedia?, Error?)]) {
        poster = StoryPoster(context: ContextManager.shared.mainContext)
        let postMedia: [StoryPoster.Media] = media.compactMap { (item, error) in
            switch item {
            case .image(let url, _, let size):
                return StoryPoster.Media(url: url, size: size)
            case .video(let url, _, let size):
                return StoryPoster.Media(url: url, size: size)
            case .frames(let url, _, let size):
                return StoryPoster.Media(url: url, size: size)
            case .none:
                return nil
            }
        }
        poster?.post(media: postMedia, title: "Post from iOS", to: blog, completion: posted)
    }
}
