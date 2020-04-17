import UIKit

class ReaderTagsTableViewController: ReaderMenuViewController {

    let readerMenuSection = ReaderMenuSectionType.tags

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.sections.removeAll()
        viewModel.setupTagsSection()

        tableView.reloadData()
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }

//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        super.tableView(tableView, numberOfRowsInSection: readerMenuSection.rawValue)
//    }

    private func adjust(_ indexPath: IndexPath) -> IndexPath {
//        var adjustedIndexPath = indexPath
//        adjustedIndexPath.section = readerMenuSection.rawValue
        return indexPath
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: adjust(indexPath))
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
