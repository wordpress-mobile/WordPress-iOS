import UIKit
import SwiftUI

final class MigrationWelcomeViewController: UIViewController {

    // MARK: - Dependencies

    private let tracker: MigrationAnalyticsTracker

    private let viewModel: MigrationWelcomeViewModel

    // MARK: - Views

    private let tableView = UITableView(frame: .zero, style: .plain)

    private lazy var headerView: MigrationHeaderView = {
        let view = MigrationHeaderView(configuration: viewModel.configuration.headerConfiguration)
        view.translatesAutoresizingMaskIntoConstraints = true
        view.directionalLayoutMargins = Constants.tableHeaderViewMargins
        return view
    }()

    private lazy var bottomSheet: MigrationActionsView = {
        let actionsView = MigrationActionsView(configuration: viewModel.configuration.actionsConfiguration)
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        actionsView.primaryHandler = { [weak self] configuration in
            self?.tracker.track(.welcomeScreenContinueTapped)
            configuration.primaryHandler?()
        }
        actionsView.secondaryHandler = { [weak self] configuration in
            self?.tracker.track(.welcomeScreenHelpButtonTapped)
            configuration.secondaryHandler?()
        }
        return actionsView
    }()

    private let blogCellID = "blogCelID"

    // MARK: - Lifecycle

    init(viewModel: MigrationWelcomeViewModel, tracker: MigrationAnalyticsTracker = .init()) {
        self.viewModel = viewModel
        self.tracker = tracker
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = MigrationAppearance.backgroundColor
        self.setupTableView()
        self.setupBottomSheet()
        self.setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tracker.track(.welcomeScreenShown)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.sizeToFitHeaderView()
        self.updateTableViewContentInset()
    }

    // MARK: - Setup and Updates

    private func setupTableView() {
        self.tableView.backgroundColor = .clear
        self.tableView.directionalLayoutMargins.leading = Constants.tableViewLeadingMargin
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: blogCellID)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.tableHeaderView = headerView
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        self.view.addSubview(tableView)
        self.view.pinSubviewToAllEdges(tableView)
    }

    private func setupNavigationBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(email: viewModel.gravatarEmail) { [weak self] () -> Void in
            guard let self else {
                return
            }
            self.tracker.track(.welcomeScreenAvatarTapped)
            self.viewModel.configuration.actionsConfiguration.secondaryHandler?()
        }
    }

    private func setupBottomSheet() {
        self.view.addSubview(bottomSheet)
        NSLayoutConstraint.activate([
            bottomSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Increases the tableView's bottom inset so it doesn't get covered by  the bottom actions sheet.
    private func updateTableViewContentInset() {
        let bottomInset = -view.safeAreaInsets.bottom + bottomSheet.bounds.height
        self.tableView.contentInset.bottom = bottomInset + Constants.tableViewBottomInsetMargin
        self.tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    // MARK: - Constants

    private struct Constants {
        /// Used to add a gap between the `tableView` last row and the bottom sheet top edge.
        static let tableViewBottomInsetMargin = CGFloat(20)

        /// Used to align the `tableView`'s leading edge with the tableView header's leading edge.
        static let tableViewLeadingMargin = CGFloat(30)

        /// Used for the `tableHeaderView` layout guide margins.
        static let tableHeaderViewMargins = NSDirectionalEdgeInsets(top: 0, leading: 30, bottom: 30, trailing: 30)
    }
}

// MARK: - UITableViewDataSource

extension MigrationWelcomeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let blog = viewModel.sites[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: blogCellID, for: indexPath)
        cell.contentConfiguration = UIHostingConfiguration {
            BlogListSiteView(site: blog)
        }
        return cell
    }
}
