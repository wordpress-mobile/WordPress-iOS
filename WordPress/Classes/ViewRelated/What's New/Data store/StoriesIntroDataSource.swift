
/// A type which can register and vend cells for a table view.
protocol CellItem {
    func registerCells(in tableView: UITableView)
    func cell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell
}

class StoriesIntroDataSource: NSObject, AnnouncementsDataSource {

    struct AnnouncementItem: CellItem {

        let title: String
        let description: String

        typealias Cell = AnnouncementCell
        private let reuseIdentifier = "announcementCell"

        func registerCells(in tableView: UITableView) {
            tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
        }

        func cell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
            (cell as? Cell)?.configure(title: title, description: description, image: nil)
            return cell
        }
    }

    struct Grid: CellItem {

        let title: String
        let items: [GridCell.Item]

        typealias Cell = GridCell
        private let reuseIdentifier = "gridCell"

        func registerCells(in tableView: UITableView) {
            tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
        }

        func cell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
            (cell as? Cell)?.configure(title: title, items: items)
            return cell
        }
    }

    var dataDidChange: (() -> Void)?
    private let items: [CellItem]

    init(items: [CellItem]) {
        self.items = items
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        return item.cell(for: indexPath, in: tableView)
    }

    func registerCells(for tableView: UITableView) {
        items.forEach { item in
            item.registerCells(in: tableView)
        }
    }
}
