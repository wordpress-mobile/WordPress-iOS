import Foundation
import WordPressFlux

protocol ActivityTypeSelectorDelegate: class {
    func didCancel(selectorViewController: ActivityTypeSelectorViewController)
    func didSelect(selectorViewController: ActivityTypeSelectorViewController, groups: [ActivityGroup])
}

class ActivityTypeSelectorViewController: UITableViewController {
    private let store: ActivityStore!
    private let site: JetpackSiteRef!

    private var storeReceipt: Receipt?
    private var selectedGroupsKeys: [String] = []

    private var groups: [ActivityGroup] {
        return store.state.groups[site] ?? []
    }

    weak var delegate: ActivityTypeSelectorDelegate?

    init(site: JetpackSiteRef, store: ActivityStore) {
        self.site = site
        self.store = store
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        setupNavButtons()

        store.actionDispatcher.dispatch(ActivityAction.refreshGroups(site: self.site, afterDate: nil, beforeDate: nil))

        storeReceipt = store.onChange {
            self.tableView.reloadData()
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
        delegate?.didSelect(selectorViewController: self, groups: groups.filter { selectedGroupsKeys.contains($0.key) })
    }

    @objc private func cancel() {
        delegate?.didCancel(selectorViewController: self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.groupCellIdentifier, for: indexPath) as? WPTableViewCell,
              let activityGroup = store.state.groups[site]?[indexPath.row] else {
            return UITableViewCell()
        }

        cell.textLabel?.text = "\(activityGroup.name) (\(activityGroup.count))"
        cell.accessoryType = selectedGroupsKeys.contains(activityGroup.key) ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)

        let selectedGroupKey = groups[indexPath.row].key

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
