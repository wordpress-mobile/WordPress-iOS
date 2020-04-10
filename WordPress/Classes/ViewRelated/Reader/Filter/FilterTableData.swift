struct TableDataItem {
    let topic: ReaderAbstractTopic
    let configure: (UITableViewCell) -> Void
}

class FilterTableViewDataSource: NSObject, UITableViewDataSource {

    let data: [TableDataItem]
    private let reuseIdentifier: String

    init(data: [TableDataItem], reuseIdentifier: String) {
        self.data = data
        self.reuseIdentifier = reuseIdentifier
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        item.configure(cell)

        return cell
    }
}

class SiteTableViewCell: UITableViewCell, GhostableView {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        detailTextLabel?.textColor = UIColor.systemGray
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func ghostAnimationWillStart() {
        contentView.subviews.forEach { view in
            view.isGhostableDisabled = true
        }
        textLabel?.text = "TEST LABEL Text Label"
        textLabel?.isGhostableDisabled = false
        detailTextLabel?.text = "TEST LABEL sdflsjlwe lsdfjsldjsl sidjflsidj"
        detailTextLabel?.isGhostableDisabled = false
    }
}
