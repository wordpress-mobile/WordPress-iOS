class QuickStartChecklistManager: NSObject {
    typealias QuickStartChecklistDidSelectTour = (QuickStartTour) -> Void

    private var blog: Blog
    private var tours: [QuickStartTour]
    private var title: String
    private var completedToursKeys = Set<String>()
    private var didSelectTour: QuickStartChecklistDidSelectTour

    init(blog: Blog,
         tours: [QuickStartTour],
         title: String,
         didSelectTour: @escaping QuickStartChecklistDidSelectTour) {
        self.blog = blog
        self.tours = tours
        self.title = title
        self.didSelectTour = didSelectTour
        super.init()
        reloadData()
    }

    func reloadData() {
        let completed = (blog.completedQuickStartTours ?? []).map { $0.tourID }
        completedToursKeys = Set(completed)
    }

    func tour(at indexPath: IndexPath) -> QuickStartTour {
        return tours[indexPath.row]
    }
}

extension QuickStartChecklistManager: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tours.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell else {
            return UITableViewCell()
        }
        let tour = self.tour(at: indexPath)
        let completed = isCompleted(tour: tour)
        cell.configure(tour: tour, completed: completed)
        return cell
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
        let tour = self.tour(at: indexPath)
        didSelectTour(tour)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: QuickStartChecklistHeader.identifier) as? QuickStartChecklistHeader
        headerView?.title = title
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.headerHeight
    }
}

private extension QuickStartChecklistManager {

    func isCompleted(tour: QuickStartTour) -> Bool {
        return completedToursKeys.contains(tour.key)
    }
}

private extension QuickStartChecklistManager {
    enum Constants {
        static let headerHeight: CGFloat = 204
    }
}
