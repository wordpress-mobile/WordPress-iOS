import Foundation

class ReaderDetailLikesListController: UITableViewController {

    // MARK: - Properties
    private let post: ReaderPost
    private var likesListController: LikesListController?
    private var totalLikes = 0

    // MARK: - Init
    init(post: ReaderPost, totalLikes: Int) {
        self.post = post
        self.totalLikes = totalLikes
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View
    override func viewDidLoad() {
        configureViewTitle()
        configureTable()
    }

}

private extension ReaderDetailLikesListController {

    func configureViewTitle() {
        let titleFormat = totalLikes == 1 ? TitleFormats.singular : TitleFormats.plural
        navigationItem.title = String(format: titleFormat, totalLikes)
    }

    func configureTable() {
        tableView.register(LikeUserTableViewCell.defaultNib,
                           forCellReuseIdentifier: LikeUserTableViewCell.defaultReuseID)

        likesListController = LikesListController(tableView: tableView, post: post, delegate: self)
        tableView.delegate = likesListController
        tableView.dataSource = likesListController

        // Call refresh to ensure that the controller fetches the data.
        likesListController?.refresh()
    }

    struct TitleFormats {
        static let singular = NSLocalizedString("%1$d Like",
                                                comment: "Singular format string for view title displaying the number of post likes. %1$d is the number of likes.")
        static let plural = NSLocalizedString("%1$d Likes",
                                              comment: "Plural format string for view title displaying the number of post likes. %1$d is the number of likes.")
    }

}

// MARK: - LikesListController Delegate
//
extension ReaderDetailLikesListController: LikesListControllerDelegate {

    func didSelectUser(_ user: LikeUser, at indexPath: IndexPath) {
        // TODO: show user profile
    }

    func showErrorView() {
        // TODO: show NRV
    }

}
