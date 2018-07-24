class QuickStartChecklistView: UITableViewController {
    private var dataSource: QuickStartChecklistDataSource? {
        didSet {
            self.tableView?.dataSource = dataSource
        }
    }
    @objc public var dotComID: NSNumber? {
        didSet {
            guard let dotComID = dotComID else {
                return
            }
            dataSource = QuickStartChecklistDataSource(blogID: dotComID.intValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: .zero)
        self.tableView = tableView

        let cellNib = UINib(nibName: "QuickStartChecklistCell", bundle: Bundle(for: QuickStartChecklistCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: QuickStartChecklistCell.reuseIdentifier)
    }
}

private class QuickStartChecklistDataSource: NSObject, UITableViewDataSource {
    init(blogID: Int) {
        // load storage here
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QuickStartTourGuide.checklistTours.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell {
            cell.tour = QuickStartTourGuide.checklistTours[indexPath.row]
            return cell
        }
        return UITableViewCell()
    }
}
