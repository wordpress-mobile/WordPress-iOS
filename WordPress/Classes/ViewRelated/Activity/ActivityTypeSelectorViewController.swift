import Foundation
import WordPressFlux

protocol ActivityTypeSelectorDelegate: AnyObject {
    func didCancel(selectorViewController: ActivityTypeSelectorViewController)
    func didSelect(selectorViewController: ActivityTypeSelectorViewController, groups: [ActivityGroup])
}

class ActivityTypeSelectorViewController: UITableViewController {
    private let viewModel: ActivityListViewModel!

    private var storeReceipt: Receipt?
    private var selectedGroupsKeys: [String] = []

    private var noResultsViewController: NoResultsViewController?

    weak var delegate: ActivityTypeSelectorDelegate?

    init(viewModel: ActivityListViewModel) {
        self.viewModel = viewModel
        self.selectedGroupsKeys = viewModel.selectedGroups.map { $0.key }
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        setupNavButtons()

        viewModel.refreshGroups()

        updateNoResults()

        storeReceipt = viewModel.store.onChange { [weak self] in
            self?.tableView.reloadData()
            self?.updateNoResults()
        }

        title = NSLocalizedString("Filter by activity type", comment: "Title of a screen that shows activity types so the user can filter using them (eg.: posts, images, users)")
    }

    private func configureTableView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: Constants.groupCellIdentifier)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private func setupNavButtons() {
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Label for Done button"), style: .done, target: self, action: #selector(done))
        navigationItem.setRightBarButton(doneButton, animated: false)

        navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel)), animated: false)
    }

    @objc private func done() {
        let selectedGroups = viewModel.groups.filter { selectedGroupsKeys.contains($0.key) }

        delegate?.didSelect(selectorViewController: self, groups: selectedGroups)
    }

    @objc private func cancel() {
        delegate?.didCancel(selectorViewController: self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.groupCellIdentifier, for: indexPath) as? WPTableViewCell else {
            return UITableViewCell()
        }

        let activityGroup = viewModel.groups[indexPath.row]

        cell.textLabel?.text = "\(activityGroup.name) (\(activityGroup.count))"
        cell.accessoryType = selectedGroupsKeys.contains(activityGroup.key) ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)

        let selectedGroupKey = viewModel.groups[indexPath.row].key

        if selectedGroupsKeys.contains(selectedGroupKey) {
            cell?.accessoryType = .none
            selectedGroupsKeys = selectedGroupsKeys.filter { $0 != selectedGroupKey }
        } else {
            cell?.accessoryType = .checkmark
            selectedGroupsKeys.append(selectedGroupKey)
        }
    }


    private enum Constants {
        static let groupCellIdentifier = "GroupCellIdentifier"
    }
}

// MARK: - NoResults Handling

private extension ActivityTypeSelectorViewController {

    func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsGroupsViewModel() {
            showNoResults(noResultsViewModel)
        } else {
            noResultsViewController?.view.isHidden = true
        }
    }

    func showNoResults(_ viewModel: NoResultsViewController.Model) {
        if noResultsViewController == nil {
            noResultsViewController = NoResultsViewController.controller()
            noResultsViewController?.delegate = self

            guard let noResultsViewController = noResultsViewController else {
                return
            }

            if noResultsViewController.view.superview != tableView {
                tableView.addSubview(withFadeAnimation: noResultsViewController.view)
            }

            addChild(noResultsViewController)
        }

        noResultsViewController?.bindViewModel(viewModel)
        noResultsViewController?.didMove(toParent: self)
        noResultsViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        tableView.pinSubviewToSafeArea(noResultsViewController!.view)
        noResultsViewController?.view.isHidden = false
    }

}

// MARK: - NoResultsViewControllerDelegate

extension ActivityTypeSelectorViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        viewModel.refreshGroups()
    }
}
