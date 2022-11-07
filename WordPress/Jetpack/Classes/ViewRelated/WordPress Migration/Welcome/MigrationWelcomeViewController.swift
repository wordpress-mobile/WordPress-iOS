import UIKit

final class MigrationWelcomeViewController: UIViewController {

    // MARK: - Data

    private let viewModel: MigrationWelcomeViewModel

    // MARK: - Views

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let headerView: MigrationHeaderView = {
        let view = MigrationHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.directionalLayoutMargins = Constants.tableHeaderViewMargins
        return view
    }()

    private let bottomSheet = MigrationActionsView()

    // MARK: - Lifecycle

    init(viewModel: MigrationWelcomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .ungroupedListBackground
        self.view.backgroundColor = tableView.backgroundColor
        self.setupTableView()
        self.setupBottomSheet()
        self.setupNavigationBar()
        self.updateTableHeaderView(with: viewModel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.sizeToFitHeaderView()
        self.updateTableViewContentInset()
    }

    // MARK: - Setup and Updates

    private func setupTableView() {
        self.tableView.directionalLayoutMargins.leading = Constants.tableViewLeadingMargin
        self.tableView.register(MigrationWelcomeBlogTableViewCell.self, forCellReuseIdentifier: MigrationWelcomeBlogTableViewCell.defaultReuseID)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.tableHeaderView = headerView
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        self.view.addSubview(tableView)
        self.view.pinSubviewToAllEdges(tableView)
    }

    private func setupNavigationBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(email: viewModel.gravatarEmail)
    }

    private func setupBottomSheet() {
        self.bottomSheet.translatesAutoresizingMaskIntoConstraints = false
        self.bottomSheet.primaryButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        self.view.addSubview(bottomSheet)
        NSLayoutConstraint.activate([
            bottomSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateTableHeaderView(with viewModel: MigrationWelcomeViewModel) {
        self.headerView.imageView.image = viewModel.image
        self.headerView.titleLabel.text = viewModel.title
        self.headerView.primaryDescriptionLabel.text = viewModel.descriptions.primary
        self.headerView.secondaryDescriptionLabel.text = viewModel.descriptions.secondary
        self.bottomSheet.primaryButton.setTitle(viewModel.actions.primary.title, for: .normal)
        self.bottomSheet.secondaryButton.setTitle(viewModel.actions.secondary.title, for: .normal)
    }

    /// Increases the tableView's bottom inset so it doesn't cover the bottom actions sheet.
    private func updateTableViewContentInset() {
        let bottomInset = -view.safeAreaInsets.bottom + bottomSheet.bounds.height
        self.tableView.contentInset.bottom = bottomInset + Constants.tableViewBottomInsetMargin
        self.tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    // MARK: - User Interaction

    @objc private func didTapContinue() {
        self.viewModel.actions.primary.handler()
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
        return viewModel.blogListDataSource.numberOfSections(in: tableView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.blogListDataSource.tableView(tableView, numberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let blog = viewModel.blogListDataSource.blog(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: MigrationWelcomeBlogTableViewCell.defaultReuseID, for: indexPath) as! MigrationWelcomeBlogTableViewCell
        cell.update(with: blog)
        return cell
    }
}
