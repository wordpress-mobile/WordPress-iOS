class QuickStartChecklistView: UITableViewController {
    private let dataSource = QuickStartChecklistDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: .zero)
        tableView.dataSource = dataSource
        self.tableView = tableView
        
        let cellNib = UINib(nibName: "QuickStartChecklistCell", bundle: Bundle(for: QuickStartChecklistCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: QuickStartChecklistCell.reuseIdentifier)
    }
}

private class QuickStartChecklistDataSource: NSObject, UITableViewDataSource {
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
