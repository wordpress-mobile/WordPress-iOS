// Decorates a UITableViewDataSource & UITableViewDelegate to implement a table view header
final class TitleSubtitleHeaderDataCoordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
    private let decorated: UITableViewDataSource & UITableViewDelegate
    private let headerData: SiteCreationHeaderData

    private struct Constants {
        // Arbitrary value, will have to be updated
        static let headerHeight: CGFloat = 200
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
        title.textAlignment = .center
        title.numberOfLines = 0

        let subtitle = UILabel(frame: .zero)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.text = headerData.subtitle
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [title, subtitle])
        stackView.axis = .vertical
        stackView.spacing = 20

        return stackView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.headerHeight
    }
}
