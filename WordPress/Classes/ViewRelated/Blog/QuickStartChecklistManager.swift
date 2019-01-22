class QuickStartChecklistManager: NSObject {
    typealias QuickStartChecklistDidSelectTour = (String) -> Void

    private var blog: Blog
    private var todoTours: [QuickStartTour] = []
    private var completedTours: [QuickStartTour] = []
    private var tours: [QuickStartTour]
    private var completedToursKeys = Set<String>()
    private var didSelectTour: QuickStartChecklistDidSelectTour

    init(blog: Blog, tours: [QuickStartTour], didSelectTour: @escaping QuickStartChecklistDidSelectTour) {
        self.blog = blog
        self.tours = tours
        self.didSelectTour = didSelectTour
        super.init()
        reloadData()
    }


    // MARK: - Public functions

    func reloadData() {
        let completed = (blog.completedQuickStartTours ?? []).map { $0.tourID }
        let skipped = (blog.skippedQuickStartTours ?? []).map { $0.tourID }

        completedToursKeys = Set(completed).union(Set(skipped))
        todoTours = tours.filter(!isCompleted)
        completedTours = tours.filter(isCompleted)
    }

    func tour(at indexPath: IndexPath) -> QuickStartTour {
        return tours(at: indexPath.section)[indexPath.row]
    }
}

extension QuickStartChecklistManager: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tours(at: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell {
            let tour = self.tour(at: indexPath)
            cell.tour = tour
            cell.completed = isCompleted(tour: tour)
            cell.lastRow = isLastTour(at: indexPath)
            return cell
        }
        return UITableViewCell()
    }
}

extension QuickStartChecklistManager: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tour(at: indexPath) is QuickStartCreateTour {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tourGuide = QuickStartTourGuide.find() else {
                return
        }

        let tour = self.tour(at: indexPath)
        tourGuide.start(tour: tour, for: blog)
        didSelectTour(tour.analyticsKey)
    }
}

private extension QuickStartChecklistManager {
    func isLastTour(at indexPath: IndexPath) -> Bool {
        let tours = self.tours(at: indexPath.section)
        return (tours.count - 1) == indexPath.row
    }

    func tours(at section: Int) -> [QuickStartTour] {
        return section == Sections.todo.rawValue ? todoTours : completedTours
    }

    func isCompleted(tour: QuickStartTour) -> Bool {
        return completedToursKeys.contains(tour.key)
    }
}

private enum Sections: Int {
    case todo
    case completed
}
