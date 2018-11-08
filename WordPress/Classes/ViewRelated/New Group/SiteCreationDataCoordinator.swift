// Decorates a UITableViewDataSource & UITableViewDelegate to implement a table view header
final class SiteCreationDataCoordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
    private let decorated: UITableViewDataSource & UITableViewDelegate
    private let headerData: SiteCreationHeaderData

    private struct Constants {
        // Arbitrary value, will have to be updated
        static let headerHeight: CGFloat = 80
    }

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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = headerData.title

        let subTitle = UILabel(frame: .zero)
        subTitle.translatesAutoresizingMaskIntoConstraints = false
        subTitle.text = headerData.subtitle

        let stackView = UIStackView(arrangedSubviews: [title, subTitle])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20

        return stackView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.headerHeight
    }
}
