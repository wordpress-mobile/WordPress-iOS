class ReaderTagsTableViewController: ReaderMenuViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sections.removeAll()
        viewModel.setupTagsSection()

        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        guard cell.textLabel?.text != "Add a Tag" else { return cell }
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        button.setImage(UIImage.gridicon(.crossSmall), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        button.imageView?.tintColor = UIColor.muriel(color: MurielColor(name: .gray, shade: .shade10))
        button.addTarget(self, action: #selector(tappedAccessory(_:)), for: .touchUpInside)
        cell.accessoryView = button
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {

        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        guard let topic = menuItem.topic as? ReaderTagTopic else {
            return
        }

        unfollowTagTopic(topic)
    }

    @objc func tappedAccessory(_ sender: UIButton) {
        if let point = sender.superview?.convert(sender.center, to: tableView),
            let indexPath = tableView.indexPathForRow(at: point) {
            tableView.delegate?.tableView?(tableView, accessoryButtonTappedForRowWith: indexPath)
        }
    }

    override func menuDidReloadContent() {
        super.menuDidReloadContent()
        viewModel.sections.removeAll()
        viewModel.setupTagsSection()

        tableView.reloadData()
    }
}
