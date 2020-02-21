import Foundation

class PostUploadProgressTracker<PostType: AbstractPost> {
    private let post: PostType
    private var progressObserverUUID: UUID? = nil
    
    var progressBlock: ((Float) -> Void)? = nil {
        didSet {
            if let _ = oldValue, let uuid = progressObserverUUID {
                MediaCoordinator.shared.removeObserver(withUUID: uuid)
            }

            if let progressBlock = progressBlock {
                progressObserverUUID = MediaCoordinator.shared.addObserver({ [weak self] (_, _) in
                    if let post = self?.post {
                        progressBlock(Float(MediaCoordinator.shared.totalProgress(for: post)))
                    }
                }, forMediaFor: post)
            }
        }
    }
    
    init(with post: PostType) {
        self.post = post
    }
}

class PageCellModel {
    private let page: Page
    
    let uploadProgressTracker: PostUploadProgressTracker<Page>
    
    init(with page: Page) {
        self.page = page
        self.uploadProgressTracker = PostUploadProgressTracker(with: page)
    }
}
