import WordPressFlux


protocol AnnouncementsDataSource: UITableViewDataSource {
    func registerCells(for tableView: UITableView)
    var dataDidChange: (() -> Void)? { get set }
}


class FeatureAnnouncementsDataSource: NSObject, AnnouncementsDataSource {

    let store = RemoteAnnouncementsStore()

    private var subscription: Receipt?

    private let cellTypes: [String: UITableViewCell.Type]
    private var features: [WordPressKit.Feature] {
        // TODO - WHATSNEW: this is only to test data coming in from the endpoint. Will change
        store.announcements[safe: 0]?.features ?? []
    }
    private let findOutMoreLink: String

    var dataDidChange: (() -> Void)?

    init(features: [WordPressKit.Feature], cellTypes: [String: UITableViewCell.Type], findOutMoreLink: String) {
        self.cellTypes = cellTypes
        self.findOutMoreLink = findOutMoreLink
        super.init()

        subscription = store.onChange {
            self.dataDidChange?()
        }
        // TODO - WHATSNEW: the hardcoded arguments are only to test data coming in from the endpoint. Will change
        store.getAnnouncements(appId: "3", appVersion: "15.2")
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
            cell.configure(with: URL(string: findOutMoreLink))
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "announcementCell", for: indexPath) as? AnnouncementCell ?? AnnouncementCell()
        cell.configure(feature: features[indexPath.row])
        return cell
    }
}
