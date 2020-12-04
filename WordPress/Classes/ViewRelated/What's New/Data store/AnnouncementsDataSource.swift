
protocol AnnouncementsDataSource: UITableViewDataSource {
    func registerCells(for tableView: UITableView)
    var dataDidChange: (() -> Void)? { get set }
}


class FeatureAnnouncementsDataSource: NSObject, AnnouncementsDataSource {

    private let store: AnnouncementsStore

    private let cellTypes: [String: UITableViewCell.Type]
    private var features: [WordPressKit.Feature] {
        store.announcements.reduce(into: [WordPressKit.Feature](), {
            $0.append(contentsOf: $1.features)
        })
    }

    var dataDidChange: (() -> Void)?

    init(store: AnnouncementsStore, cellTypes: [String: UITableViewCell.Type]) {
        self.store = store
        self.cellTypes = cellTypes
        super.init()
    }

    func registerCells(for tableView: UITableView) {
        cellTypes.forEach {
            tableView.register($0.value, forCellReuseIdentifier: $0.key)
        }
    }

    func numberOfSections(in: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return features.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row <= features.count - 1 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "findOutMoreCell", for: indexPath) as? FindOutMoreCell ?? FindOutMoreCell()
            cell.configure(with: URL(string: store.announcements.first?.detailsUrl ?? ""))
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "announcementCell", for: indexPath) as? AnnouncementCell ?? AnnouncementCell()
        cell.configure(feature: features[indexPath.row])
        return cell
    }
}
