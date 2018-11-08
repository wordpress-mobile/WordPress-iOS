final class SiteCreationDataCoordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
    private let decorated: UITableViewDataSource & UITableViewDelegate
    private let headerData: SiteCreationHeaderData

    init(decorated: UITableViewDataSource & UITableViewDelegate, headerData: SiteCreationHeaderData) {
        self.decorated = decorated
        self.headerData = headerData
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return decorated.tableView(tableView, numberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return decorated.tableView(tableView, cellForRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Avoid force unwrapping
        decorated.tableView!(tableView, didSelectRowAt: indexPath)
    }
}
