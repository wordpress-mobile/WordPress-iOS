
protocol AnnouncementsDataSource: UITableViewDataSource {
    func registerCells(for tableView: UITableView)
    var dataDidChange: (() -> Void)? { get set }
}


class FeatureAnnouncementsDataSource: NSObject, AnnouncementsDataSource {

    private let features: [WordPressKit.Feature]
    private let detailsUrl: String
    private let cellTypes: [String: UITableViewCell.Type]

    var dataDidChange: (() -> Void)?

    init(features: [WordPressKit.Feature], detailsUrl: String, cellTypes: [String: UITableViewCell.Type]) {
        self.features = features
        self.detailsUrl = detailsUrl
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
            cell.configure(with: URL(string: detailsUrl))
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "announcementCell", for: indexPath) as? AnnouncementCell ?? AnnouncementCell()
        cell.configure(feature: features[indexPath.row])
        return cell
    }
}
