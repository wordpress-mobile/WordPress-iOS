
struct ActivityContentRouter: ContentRouter {
    private let coordinator: ContentCoordinator
    private let activity: FormattableActivity
    private let readerCoordinator: ReaderCoordinator

    init(controller: UIViewController, activity: FormattableActivity, context: NSManagedObjectContext) {
        coordinator = ContentCoordinator(controller: controller, context: context)
        readerCoordinator = ReaderCoordinator(
            readerNavigationController: controller.navigationController!)
        self.activity = activity
    }

    func routeTo(_ url: URL) {
        guard let range = getRange(with: url) else {
            return
        }
        displayContent(of: range, with: url)
    }

    private func displayContent(of range: FormattableContentRange, with url: URL) {
        switch range.kind {
        case .post:
            guard let postRange = range as? ActivityPostRange else {
                fallthrough
            }
            let postID = postRange.postID as NSNumber
            let siteID = postRange.siteID as NSNumber
            try? coordinator.displayReaderWithPostId(postID, siteID: siteID)
        case .comment:
            guard let commentRange = range as? ActivityCommentRange else {
                fallthrough
            }
            let postID = commentRange.postID as NSNumber
            let siteID = commentRange.siteID as NSNumber
            try? coordinator.displayCommentsWithPostId(postID, siteID: siteID)
        default:
            coordinator.displayWebViewWithURL(url)
        }
    }

    private func getRange(with url: URL) -> FormattableContentRange? {
        return activity.range(with: url)
    }
}
