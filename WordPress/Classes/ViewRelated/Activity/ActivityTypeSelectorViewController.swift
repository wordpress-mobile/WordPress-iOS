import Foundation
import WordPressFlux

class ActivityTypeSelectorViewController: UITableViewController {
    private let store: ActivityStore!
    private let site: JetpackSiteRef!

    private var storeReceipt: Receipt?

    private var groups: [ActivityGroup] {
        return store.state.groups[site] ?? []
    }

    private var selectedGroups: [String] = []

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

        store.actionDispatcher.dispatch(ActivityAction.refreshGroups(site: self.site, afterDate: nil, beforeDate: nil))

        storeReceipt = store.onChange {
            self.tableView.reloadData()
        }
    }

    private func configureTableView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: Constants.groupCellIdentifier)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    private enum Constants {
        static let groupCellIdentifier = "GroupCellIdentifier"
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
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)

        let selectedGroupKey = groups[indexPath.row].key

        if selectedGroups.contains(selectedGroupKey) {
            cell?.accessoryType = .none
            selectedGroups = selectedGroups.filter { $0 != selectedGroupKey }
        } else {
            cell?.accessoryType = .checkmark
            selectedGroups.append(selectedGroupKey)
        }
    }
}
