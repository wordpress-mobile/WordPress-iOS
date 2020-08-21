
protocol AnnouncementsDataSource: UITableViewDataSource {
    func registerCells(for tableView: UITableView)
}


class FeatureAnnouncementsDataSource: NSObject, AnnouncementsDataSource {

    private let cellTypes: [String: UITableViewCell.Type]
    private let announcements: [Announcement]
    private let findOutMoreLink: String

    init(announcements: [Announcement], cellTypes: [String: UITableViewCell.Type], findOutMoreLink: String) {
        self.announcements = announcements
        self.cellTypes = cellTypes
        self.findOutMoreLink = findOutMoreLink
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
        return announcements.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row <= announcements.count - 1 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "findOutMoreCell", for: indexPath) as? FindOutMoreCell ?? FindOutMoreCell()
            cell.configure(with: URL(string: findOutMoreLink))
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "announcementCell", for: indexPath) as? AnnouncementCell ?? AnnouncementCell()
        cell.configure(announcement: announcements[indexPath.row])
        return cell
    }
}
