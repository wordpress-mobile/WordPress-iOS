import Foundation
import WordPressUI
import UIKit

protocol CommentDetailInfoView: AnyObject {
    func showAuthorPage(url: URL)
}

final class CommentDetailInfoViewController: UIViewController {
    private static let cellReuseIdentifier = "infoCell"
    private let tableView: UITableView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UITableView())

    private let viewModel: CommentDetailInfoViewModelType

    init(viewModel: CommentDetailInfoViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        addTableViewConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setPreferredContentSize()
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }

    private func addTableViewConstraints() {
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
    }

    private func setPreferredContentSize() {
        tableView.layoutIfNeeded()
        preferredContentSize = tableView.contentSize
    }
}

// MARK: - CommentDetailInfoView
extension CommentDetailInfoViewController: CommentDetailInfoView {
    func showAuthorPage(url: URL) {
        let viewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url, source: "comment_detail")
        let navigationControllerToPresent = UINavigationController(rootViewController: viewController)
        present(navigationControllerToPresent, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDatasource
extension CommentDetailInfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.fetchUserDetails().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseIdentifier)
        ?? .init(style: .subtitle, reuseIdentifier: Self.cellReuseIdentifier)

        let userDetails = viewModel.fetchUserDetails()
        let info = userDetails[indexPath.item]

        cell.selectionStyle = .none
        cell.tintColor = .primary

        cell.textLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        cell.textLabel?.textColor = .textSubtle
        cell.textLabel?.text = info.title

        cell.detailTextLabel?.font = WPStyleGuide.fontForTextStyle(.body)
        cell.detailTextLabel?.textColor = .text
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = info.description.isEmpty ? " " : info.description // prevent the cell from collapsing due to empty label text.

        return cell
    }
}

// MARK: - UITableViewDelegate
extension CommentDetailInfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectItem(at: indexPath.item)
    }
}

// MARK: - DrawerPresentable
extension CommentDetailInfoViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        .intrinsicHeight
    }

    var allowsUserTransition: Bool {
        false
    }

    var compactWidth: DrawerWidth {
        .maxWidth
    }
}

// MARK: - ChildDrawerPositionable
extension CommentDetailInfoViewController: ChildDrawerPositionable {
    var preferredDrawerPosition: DrawerPosition {
        .collapsed
    }
}
