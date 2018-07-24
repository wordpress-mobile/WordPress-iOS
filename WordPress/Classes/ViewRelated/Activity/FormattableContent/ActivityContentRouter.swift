
struct ActivityContentRouter: ContentRouter {
    private let coordinator: ContentCoordinator
    private let activity: FormattableActivity

    init(activity: FormattableActivity, coordinator: ContentCoordinator) {
        self.coordinator = coordinator// ContentCoordinator(controller: controller, context: context)
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
        case .plugin:
            guard let pluginRange = range as? ActivityPluginRange else {
                fallthrough
            }
            let siteSlug = pluginRange.siteSlug
            let pluginSlug = pluginRange.pluginSlug
            try? coordinator.displayPlugin(withSlug: pluginSlug, on: siteSlug)
        default:
            coordinator.displayWebViewWithURL(url)
        }
    }

    private func getRange(with url: URL) -> FormattableContentRange? {
        return activity.range(with: url)
    }
}
