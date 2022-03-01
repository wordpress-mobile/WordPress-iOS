import UIKit

class NotificationCommentDetailViewController: UIViewController, NoResultsViewHost {

    // MARK: - Properties

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

    private var commentDetailViewController: CommentDetailViewController?
    private weak var notificationDelegate: CommentDetailsNotificationDelegate?
    private let managedObjectContext = ContextManager.shared.mainContext

    private lazy var commentService: CommentService = {
        return .init(managedObjectContext: managedObjectContext)
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
        title = notification.title
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

        if commentDetailViewController != nil {
            commentDetailViewController?.refreshView(comment: comment, notification: notification)
        } else {
            let commentDetailViewController = CommentDetailViewController(comment: comment,
                                                                      notification: notification,
                                                                      notificationDelegate: notificationDelegate,
                                                                      managedObjectContext: managedObjectContext)

            commentDetailViewController.view.frame = view.frame
            add(commentDetailViewController)
            view.pinSubviewToAllEdges(commentDetailViewController.view)
            self.commentDetailViewController = commentDetailViewController
        }

        configureNavBarButtons()
    }

    func loadComment() {
        showLoadingView()

        fetchParentCommentIfNeeded(completion: { [weak self] in
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
    }

    func loadCommentFromCache(_ commentID: NSNumber?) -> Comment? {
        guard let commentID = commentID,
              let blog = blog else {
                  DDLogError("Notification Comment: unable to load comment due to missing information.")
                  return nil
              }

        return commentService.findComment(withID: commentID, in: blog)
    }

    func fetchComment(_ commentID: NSNumber?, completion: @escaping (Comment?) -> Void) {
        guard let commentID = commentID,
              let blog = blog else {
                  DDLogError("Notification Comment: unable to fetch comment due to missing information.")
                  completion(nil)
                  return
              }

        commentService.loadComment(withID: commentID, for: blog, success: { comment in
            completion(comment)
        }, failure: { error in
            completion(nil)
        })
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

}
