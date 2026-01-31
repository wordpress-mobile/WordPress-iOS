import Foundation
import WordPressData
import WordPressUI
import SwiftUI

final class ReaderDetailLikesListController: UIViewController {

    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .plain)
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
        super.viewDidLoad()

        configureViewTitle()
        configureTableView()
        WPAnalytics.track(.likeListOpened, properties: ["list_type": "post", "source": "like_reader_list"])
    }
}

private extension ReaderDetailLikesListController {

    func configureViewTitle() {
        let titleFormat = totalLikes == 1 ? TitleFormats.singular : TitleFormats.plural
        navigationItem.title = String(format: titleFormat, totalLikes)
    }

    func configureTableView() {
        view.addSubview(tableView)
        tableView.pinEdges()

        tableView.register(LikeUserTableViewCell.defaultNib,
                           forCellReuseIdentifier: LikeUserTableViewCell.defaultReuseID)

        likesListController = LikesListController(tableView: tableView, post: post, delegate: self)
        tableView.delegate = likesListController
        tableView.dataSource = likesListController

        // The separator is controlled by LikeUserTableViewCell
        tableView.separatorStyle = .none

        // Call refresh to ensure that the controller fetches the data.
        likesListController?.refresh()
    }

    func displayUserProfile(_ user: LikeUser, from indexPath: IndexPath) {
        let userProfileVC = UserProfileSheetViewController(user: user)
        userProfileVC.blogUrlPreviewedSource = "reader_like_list_user_profile"
        userProfileVC.modalPresentationStyle = .popover
        userProfileVC.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath) ?? view
        userProfileVC.popoverPresentationController?.adaptiveSheetPresentationController.prefersGrabberVisible = true
        userProfileVC.popoverPresentationController?.adaptiveSheetPresentationController.detents = [.medium()]
        present(userProfileVC, animated: true)

        WPAnalytics.track(.userProfileSheetShown, properties: ["source": "like_reader_list"])
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
        displayUserProfile(user, from: indexPath)
    }

    func showErrorView(title: String, subtitle: String?) {
        let stateView = UIHostingView(view: EmptyStateView.init(title, systemImage: "exclamationmark.circle", description: subtitle))
        view.addSubview(stateView)
        stateView.pinEdges()
    }

    func updatedTotalLikes(_ totalLikes: Int) {
        self.totalLikes = totalLikes
        configureViewTitle()
    }
}
