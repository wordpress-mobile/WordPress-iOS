
protocol AnnouncementsDataSource: UITableViewDataSource {
    func registerCells(for tableView: UITableView)
    var dataDidChange: (() -> Void)? { get set }
}

typealias AnnouncementTableViewCell = UITableViewCell & Reusable & AnnouncementCellConfigurable

protocol AnnouncementCellConfigurable {
    func configure(feature: WordPressKit.Feature)
}

class FeatureAnnouncementsDataSource: NSObject, AnnouncementsDataSource {

    private let features: [WordPressKit.Feature]
    private let detailsUrl: String
    private let announcementCellType: AnnouncementTableViewCell.Type

    var dataDidChange: (() -> Void)?

    init(features: [WordPressKit.Feature], detailsUrl: String, announcementCellType: AnnouncementTableViewCell.Type) {
        self.features = features
        self.detailsUrl = detailsUrl
        self.announcementCellType = announcementCellType
        super.init()
    }

    func registerCells(for tableView: UITableView) {
        tableView.register(FindOutMoreCell.self, forCellReuseIdentifier: FindOutMoreCell.defaultReuseID)
        tableView.register(announcementCellType, forCellReuseIdentifier: announcementCellType.defaultReuseID)
    }

    func numberOfSections(in: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return features.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row <= features.count - 1 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: FindOutMoreCell.defaultReuseID, for: indexPath) as? FindOutMoreCell ?? FindOutMoreCell()
            cell.configure(with: URL(string: detailsUrl))
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: announcementCellType.defaultReuseID, for: indexPath) as? AnnouncementTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(feature: features[indexPath.row])
        return cell
    }
}
