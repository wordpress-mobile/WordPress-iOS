import UIKit

class NotificationCommentDetailViewController: UIViewController, NoResultsViewHost {

    // MARK: - Properties

    private var content: Content?

    private var notification: Notification {
        didSet {
            title = notification.title
        }
    }

    private var comment: Comment? {
        didSet {
            updateDisplayedComment()
        }
    }

    private var commentID: NSNumber? {
        notification.metaCommentID
    }

    private var blog: Blog? {
        guard let siteID = notification.metaSiteID else {
            return nil
        }
        return Blog.lookup(withID: siteID, in: managedObjectContext)
    }

    // If the user does not have permission to the Blog, it will be nil.
    // In this case, use the Post to obtain Comment information.
    private var post: ReaderPost?

    private var commentDetailViewController: CommentDetailViewController? {
        guard let content, case let .commentDetails(viewController) = content  else {
            return nil
        }
        return viewController
    }

    private weak var notificationDelegate: CommentDetailsNotificationDelegate?
    private let managedObjectContext = ContextManager.shared.mainContext

    private lazy var commentService: CommentService = {
        return .init(coreDataStack: ContextManager.shared)
    }()

    private lazy var postService: ReaderPostService = {
        return .init(coreDataStack: ContextManager.shared)
    }()

    // MARK: - Notification Navigation Buttons

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(.gridicon(.arrowUp), for: .normal)
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("Next notification", comment: "Accessibility label for the next notification button")
        return button
    }()

    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(.gridicon(.arrowDown), for: .normal)
        button.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("Previous notification", comment: "Accessibility label for the previous notification button")
        return button
    }()

    var previousButtonEnabled = false {
        didSet {
            previousButton.isEnabled = previousButtonEnabled
        }
    }

    var nextButtonEnabled = false {
        didSet {
            nextButton.isEnabled = nextButtonEnabled
        }
    }

    // MARK: - Init

    init(notification: Notification,
         notificationDelegate: CommentDetailsNotificationDelegate) {
        self.notification = notification
        self.notificationDelegate = notificationDelegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBar()
        view.backgroundColor = .basicBackground
        loadComment()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureNavBarButtons()
    }

    func refreshViewController(notification: Notification) {
        self.notification = notification
        loadComment()
    }

}

private extension NotificationCommentDetailViewController {

    func configureNavBar() {
        title = notification.title
        // Empty Back Button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    func configureNavBarButtons() {
        var barButtonItems: [UIBarButtonItem] = []

        if splitViewControllerIsHorizontallyCompact {
            barButtonItems.append(makeNavigationButtons())
        }

        if let comment = comment,
           comment.allowsModeration(),
           let commentDetailViewController = commentDetailViewController {
            barButtonItems.append(commentDetailViewController.editBarButtonItem)
        }

        navigationItem.setRightBarButtonItems(barButtonItems, animated: false)
    }

    func makeNavigationButtons() -> UIBarButtonItem {
        // Create custom view to match that in NotificationDetailsViewController.
        let buttonStackView = UIStackView(arrangedSubviews: [nextButton, previousButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = Constants.arrowButtonSpacing

        let width = (Constants.arrowButtonSize * 2) + Constants.arrowButtonSpacing
        buttonStackView.frame = CGRect(x: 0, y: 0, width: width, height: Constants.arrowButtonSize)

        return UIBarButtonItem(customView: buttonStackView)
    }

    @objc func previousButtonTapped() {
        notificationDelegate?.previousNotificationTapped(current: notification)
    }

    @objc func nextButtonTapped() {
        notificationDelegate?.nextNotificationTapped(current: notification)
    }

    func updateDisplayedComment() {
        guard let comment = comment else {
            return
        }

        // Refresh the current content if the underlying view controller supports it
        // Else, remove the existing child view controller and add a new one.
        if let commentDetailViewController {
            commentDetailViewController.refreshView(comment: comment, notification: notification)
        } else {
            self.content?.viewController.remove()
            let newContent = makeNewContent(with: comment)
            let viewController = newContent.viewController
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.add(viewController)
            self.view.pinSubviewToAllEdges(viewController.view)
            self.content = newContent
        }

        self.configureNavBarButtons()
    }

    private func makeNewContent(with comment: Comment) -> Content {
        guard !comment.allowsModeration(),
              let blog = comment.blog,
              blog.supports(.wpComRESTAPI),
              let blogID = blog.dotComID,
              let readerComments = ReaderCommentsViewController(postID: NSNumber(value: comment.postID), siteID: blogID, source: .commentNotification)
        else {
            let viewController = CommentDetailViewController(
                comment: comment,
                notification: notification,
                notificationDelegate: notificationDelegate,
                managedObjectContext: managedObjectContext
            )
            return .commentDetails(viewController)
        }
        readerComments.navigateToCommentID = commentID
        readerComments.allowsPushingPostDetails = true
        return .readerComments(readerComments)
    }

    func loadComment() {
        showLoadingView()

        loadPostIfNeeded(completion: { [weak self] in

            self?.fetchParentCommentIfNeeded(completion: { [weak self] in
                guard let self = self else {
                    return
                }

                if let comment = self.loadCommentFromCache(self.commentID) {
                    self.comment = comment
                    return
                }

                self.fetchComment(self.commentID, completion: { [weak self] comment in
                    guard let comment = comment else {
                        self?.showErrorView()
                        return
                    }

                    self?.comment = comment
                })
            })
        })
    }

    func loadPostIfNeeded(completion: @escaping () -> Void) {

        // The post is only needed if there is no Blog.
        guard blog == nil,
              let postID = notification.metaPostID,
              let siteID = notification.metaSiteID else {
                  completion()
                  return
              }

        if let post = try? ReaderPost.lookup(withID: postID, forSiteWithID: siteID, in: managedObjectContext) {
            self.post = post
            completion()
            return
        }

        postService.fetchPost(postID.uintValue,
                              forSite: siteID.uintValue,
                              isFeed: false,
                              success: { [weak self] post in
            self?.post = post
            completion()
        }, failure: { [weak self] _ in
            self?.post = nil
            completion()
        })
    }

    func loadCommentFromCache(_ commentID: NSNumber?) -> Comment? {
        guard let commentID = commentID else {
            DDLogError("Notification Comment: unable to load comment due to missing commentID.")
            return nil
        }

        if let blog = blog {
            return blog.comment(withID: commentID)
        }

        if let post = post {
            return post.comment(withID: commentID)
        }

        return nil
    }

    func fetchComment(_ commentID: NSNumber?, completion: @escaping (Comment?) -> Void) {
        guard let commentID = commentID else {
            DDLogError("Notification Comment: unable to fetch comment due to missing commentID.")
            completion(nil)
            return
        }

        if let blog = blog {
            commentService.loadComment(withID: commentID, for: blog, success: { comment in
                completion(comment)
            }, failure: { error in
                completion(nil)
            })
            return
        }

        if let post = post {
            commentService.loadComment(withID: commentID, for: post, success: { comment in
                completion(comment)
            }, failure: { error in
                completion(nil)
            })
            return
        }

        completion(nil)
    }

    func fetchParentCommentIfNeeded(completion: @escaping () -> Void) {
        // If the comment has a parent and it is not cached, fetch it so the details header is correct.
        guard let parentID = notification.metaParentID,
              loadCommentFromCache(parentID) == nil else {
                  completion()
                  return
              }

        fetchComment(parentID, completion: { _ in
            completion()
        })
    }

    struct Constants {
        static let arrowButtonSize: CGFloat = 24
        static let arrowButtonSpacing: CGFloat = 12
    }

    // MARK: - No Results Views

    func showLoadingView() {
        if let commentDetailViewController = commentDetailViewController {
            commentDetailViewController.showNoResultsView(title: NoResults.loadingTitle,
                                                          accessoryView: NoResultsViewController.loadingAccessoryView())
        } else {
            hideNoResults()
            configureAndDisplayNoResults(on: view,
                                         title: NoResults.loadingTitle,
                                         accessoryView: NoResultsViewController.loadingAccessoryView())
        }
    }

    func showErrorView() {
        if let commentDetailViewController = commentDetailViewController {
            commentDetailViewController.showNoResultsView(title: NoResults.errorTitle,
                                                          subtitle: NoResults.errorSubtitle,
                                                          imageName: NoResults.imageName)
        } else {
            hideNoResults()
            configureAndDisplayNoResults(on: view,
                                         title: NoResults.errorTitle,
                                         subtitle: NoResults.errorSubtitle,
                                         image: NoResults.imageName)
        }
    }

    struct NoResults {
        static let loadingTitle = NSLocalizedString("Loading comment...", comment: "Displayed while a comment is being loaded.")
        static let errorTitle = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading a comment.")
        static let errorSubtitle = NSLocalizedString("There was an error loading the comment.", comment: "Text displayed when there is a failure loading a comment.")
        static let imageName = "wp-illustration-notifications"
    }

    // MARK: - Types

    private enum Content {

        case commentDetails(CommentDetailViewController)
        case readerComments(ReaderCommentsViewController)

        var viewController: UIViewController {
            switch self {
            case .commentDetails(let vc): return vc
            case .readerComments(let vc): return vc
            }
        }
    }

}
