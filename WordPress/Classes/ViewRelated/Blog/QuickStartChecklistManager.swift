class QuickStartChecklistManager: NSObject {
    typealias QuickStartChecklistDidSelectTour = (QuickStartTour) -> Void

    private var blog: Blog
    private var tours: [QuickStartTour]
    private var completedToursKeys = Set<String>()
    private var didSelectTour: QuickStartChecklistDidSelectTour

    init(blog: Blog,
         tours: [QuickStartTour],
         didSelectTour: @escaping QuickStartChecklistDidSelectTour) {
        self.blog = blog
        self.tours = tours
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
        let topSeparatorIsHidden = hideTopSeparator(at: indexPath) // TODO: Won't be needed
        let lastRow = isLastTour(at: indexPath) // TODO: Won't be needed
        cell.configure(tour: tour, completed: completed, topSeparatorIsHidden: topSeparatorIsHidden, lastRow: lastRow)
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
        return WPDeviceIdentification.isiPhone() ? nil : UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return WPDeviceIdentification.isiPhone() ? 0.0 : Constants.iPadTopInset
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let tour = tour(at: indexPath)
        return isCompleted(tour: tour) ? .none : .delete
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let tour = tour(at: indexPath)
        guard isCompleted(tour: tour) == false else {
            return nil
        }

        let buttonTitle = NSLocalizedString("Skip", comment: "Button title that appears when you swipe to left the row. It indicates the possibility to skip a specific tour.")
        let skip = UIContextualAction(style: .destructive, title: buttonTitle) { [weak self] (_, _, _) in
            self?.tableView(tableView, completeTourAt: indexPath)
        }
        skip.backgroundColor = .error

        return UISwipeActionsConfiguration(actions: [skip])
    }
}

private extension QuickStartChecklistManager {
    func isLastTour(at indexPath: IndexPath) -> Bool {
        return (tours.count - 1) == indexPath.row
    }

    func hideTopSeparator(at indexPath: IndexPath) -> Bool {
        return !(WPDeviceIdentification.isiPad() && indexPath.row == 0)
    }

    func isCompleted(tour: QuickStartTour) -> Bool {
        return completedToursKeys.contains(tour.key)
    }

    func tableView(_ tableView: UITableView, completeTourAt indexPath: IndexPath) {
        let tour = tours[indexPath.row]
        completedToursKeys.insert(tour.key)
        tableView.reloadRows(at: [indexPath], with: .fade)

        WPAnalytics.trackQuickStartStat(.quickStartListItemSkipped,
                                        properties: ["task_name": tour.analyticsKey],
                                        blog: blog)
        QuickStartTourGuide.shared.complete(tour: tour, for: self.blog, postNotification: true)
    }
}

private extension QuickStartChecklistManager {
    enum Constants {
        static let iPadTopInset: CGFloat = 36.0
    }
}

private extension UITableView {
    /// Allows multiple insert/delete/reload/move calls to be animated simultaneously.
    ///
    /// - Parameters:
    ///   - update: The block that performs the relevant insert, delete, reload, or move operations.
    ///   - completion: A completion handler block to execute when all of the operations are finished. The Boolean value indicating whether the animations completed successfully. The value of this parameter is false if the animations were interrupted for any reason. On iOS 10 the value is always true.
    func perform(update: (UITableView) -> Void, _ completion: ((UITableView, Bool) -> Void)? = nil) {
        performBatchUpdates({
            update(self)
        }) { success in
            completion?(self, success)
        }
    }
}
