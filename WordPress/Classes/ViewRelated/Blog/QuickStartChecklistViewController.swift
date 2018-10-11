class QuickStartChecklistViewController: UITableViewController {
    private var dataSource: QuickStartChecklistDataSource? {
        didSet {
            self.tableView?.dataSource = dataSource
        }
    }
    private var blog: Blog?

    @objc
    convenience init(blog: Blog) {
        self.init()
        self.blog = blog
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: .zero)
        self.tableView = tableView

        let cellNib = UINib(nibName: "QuickStartChecklistCell", bundle: Bundle(for: QuickStartChecklistCell.self))
        tableView.register(cellNib, forCellReuseIdentifier: QuickStartChecklistCell.reuseIdentifier)

        guard let blog = blog else {
            return
        }
        dataSource = QuickStartChecklistDataSource(blog: blog)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let tour = dataSource?.tour(at: indexPath),
            let isCompleted = dataSource?.isCompleted(tour: tour),
            !isCompleted else {
                return nil
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // don't start a tour if it's already completed
        guard let tour = dataSource?.tour(at: indexPath),
            let blog = blog,
            let isCompleted = dataSource?.isCompleted(tour: tour),
            !isCompleted else {
                return
        }

        guard let tourGuide = QuickStartTourGuide.find() else {
            return
        }

        tourGuide.start(tour: tour, for: blog)

        self.navigationController?.popViewController(animated: true)
    }
}

private class QuickStartChecklistDataSource: NSObject, UITableViewDataSource {
    private var blog: Blog
    private var completedTours = Set<String>()

    init(blog: Blog) {
        self.blog = blog

        super.init()
        loadCompletedTours()
    }

    func loadCompletedTours() {
        guard let tours = blog.completedQuickStartTours else {
            return
        }

        for tour in tours {
            completedTours.insert(tour.tourID)
        }
    }

    // managing tours

    func tour(at indexPath: IndexPath) -> QuickStartTour {
        return QuickStartTourGuide.checklistTours[indexPath.row]
    }

    func isCompleted(tour: QuickStartTour) -> Bool {
        return completedTours.contains(tour.key)
    }

    // UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QuickStartTourGuide.checklistTours.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell {
            let tour = QuickStartTourGuide.checklistTours[indexPath.row]
            cell.tour = tour
            if isCompleted(tour: tour) {
                cell.completed = true
            }
            return cell
        }
        return UITableViewCell()
    }
}
