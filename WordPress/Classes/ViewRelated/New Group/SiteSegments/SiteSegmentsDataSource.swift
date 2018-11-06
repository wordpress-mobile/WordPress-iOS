final class SiteSegmentsDataSource: NSObject, UITableViewDataSource {
    static func cellReuseIdentifier() -> String {
        return String(describing: SiteSegmentsCell.self)
    }

    private let data: [SiteSegment]

    init(data: [SiteSegment]) {
        self.data = data
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: type(of: self).cellReuseIdentifier()) as? SiteSegmentsCell else {
            return UITableViewCell()
        }

        cell.set(segment: data[indexPath.row])

        return cell
    }
}
