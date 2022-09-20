import Foundation
import WordPressUI
import UIKit

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

    private func configureTableView() {
        tableView.dataSource = self
//        tableView.register(UITableViewCell.self, cellReuseIdentifier: Self.cellReuseIdentifier)
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
