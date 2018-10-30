final class SegmentsDataSource: NSObject, UITableViewDataSource {
    private let data: [SiteSegment]

    init(data: [SiteSegment]) {
        self.data = data
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
