import Foundation
import WordPressUI
import UIKit

protocol CommentDetailInfoView: AnyObject {
    func showAuthorPage(url: URL)
}

final class CommentDetailInfoViewController: UIViewController {
    private static let cellReuseIdentifier = "infoCell"
    private let tableView = UITableView(frame: .zero, style: .plain)

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
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
    }

    private func setPreferredContentSize() {
        tableView.layoutIfNeeded()

        preferredContentSize = CGSize(width: 320, height: tableView.contentSize.height)
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
        viewModel.userDetails.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseIdentifier)
        ?? .init(style: .subtitle, reuseIdentifier: Self.cellReuseIdentifier)

        let info = viewModel.userDetails[indexPath.item]

        cell.selectionStyle = .none
        cell.tintColor = UIAppColor.primary

        cell.textLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        cell.textLabel?.textColor = .secondaryLabel
        cell.textLabel?.text = info.title

        cell.detailTextLabel?.font = WPStyleGuide.fontForTextStyle(.body)
        cell.detailTextLabel?.textColor = .label
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

extension CommentDetailInfoViewController {
    func show(from presentingViewController: UIViewController, sourceView: UIView) {
        let navigationController = UINavigationController(rootViewController: self)
        if presentingViewController.traitCollection.horizontalSizeClass == .regular {
            navigationController.modalPresentationStyle = .popover
            navigationController.popoverPresentationController?.sourceView = sourceView
            navigationController.popoverPresentationController?.permittedArrowDirections = [.up]
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.close, primaryAction: UIAction { [weak presentingViewController] _ in
                presentingViewController?.dismiss(animated: true)
            })
            if let sheet = navigationController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                navigationController.additionalSafeAreaInsets = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0) // For grabber
            }
        }
        presentingViewController.present(navigationController, animated: true)
    }
}
