class QuickStartChecklistManager: NSObject {
    typealias QuickStartChecklistDidSelectTour = (QuickStartTour) -> Void
    typealias QuickStartChecklistDidTapHeader = (Bool) -> Void

    private var blog: Blog
    private var tours: [QuickStartTour]
    private var todoTours: [QuickStartTour] = []
    private var completedTours: [QuickStartTour] = []
    private var completedToursKeys = Set<String>()
    private var didSelectTour: QuickStartChecklistDidSelectTour
    private var didTapHeader: QuickStartChecklistDidTapHeader
    private var completedSectionCollapse: Bool = false

    init(blog: Blog,
         tours: [QuickStartTour],
         didSelectTour: @escaping QuickStartChecklistDidSelectTour,
         didTapHeader: @escaping QuickStartChecklistDidTapHeader) {
        self.blog = blog
        self.tours = tours
        self.didSelectTour = didSelectTour
        self.didTapHeader = didTapHeader
        super.init()
        reloadData()
    }

    func reloadData() {
        let completed = (blog.completedQuickStartTours ?? []).map { $0.tourID }
        completedToursKeys = Set(completed)
        todoTours = tours.filter(!isCompleted)
        completedTours = tours.filter(isCompleted)
    }

    func tour(at indexPath: IndexPath) -> QuickStartTour {
        return tours(at: indexPath.section)[indexPath.row]
    }

    func shouldShowCompleteTasksScreen() -> Bool {
        return todoTours.isEmpty
    }
}

extension QuickStartChecklistManager: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tours(at: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: QuickStartChecklistCell.reuseIdentifier) as? QuickStartChecklistCell {
            let tour = self.tour(at: indexPath)
            cell.tour = tour
            cell.completed = isCompleted(tour: tour)
            cell.topSeparatorIsHidden = hideTopSeparator(at: indexPath)
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
        let tour = self.tour(at: indexPath)
        didSelectTour(tour)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == Sections.todo.rawValue,
            !todoTours.isEmpty,
            !completedTours.isEmpty {
            return UIView()
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == Sections.todo.rawValue,
            !todoTours.isEmpty,
            !completedTours.isEmpty {
            return Sections.footerHeight
        }
        return 0.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == Sections.completed.rawValue,
            !completedTours.isEmpty {
            let headerView = Bundle.main.loadNibNamed("QuickStartChecklistHeader", owner: nil, options: nil)?.first as? QuickStartChecklistHeader
            headerView?.collapse = completedSectionCollapse
            headerView?.count = completedTours.count
            headerView?.collapseListener = { [weak self] collapse in
                self?.completedSectionCollapse = collapse
                self?.tableView(tableView, reloadCompletedSection: collapse)
            }
            return headerView
        }
        return WPDeviceIdentification.isiPhone() ? nil : UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Sections.completed.rawValue,
            !completedTours.isEmpty {
            return Sections.headerHeight
        }
        return WPDeviceIdentification.isiPhone() ? 0.0 : Sections.iPadTopInset
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let section = Sections(rawValue: indexPath.section), section == .todo else {
            return .none
        }
        return .delete
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let section = Sections(rawValue: indexPath.section), section == .todo else {
            return nil
        }

        let buttonTitle = NSLocalizedString("Skip", comment: "Button title that appears when you swipe to left the row. It indicates the possibility to skip a specific tour.")
        let skip = UITableViewRowAction(style: .destructive, title: buttonTitle) { [weak self] (_, indexPath) in
            self?.tableView(tableView, completeTourAt: indexPath)
        }
        skip.backgroundColor = .error
        return [skip]
    }
}

private extension QuickStartChecklistManager {
    func isLastTour(at indexPath: IndexPath) -> Bool {
        let tours = self.tours(at: indexPath.section)
        return (tours.count - 1) == indexPath.row
    }

    func hideTopSeparator(at indexPath: IndexPath) -> Bool {
        guard let section = Sections(rawValue: indexPath.section) else {
            return true
        }

        switch section {
        case .todo:
            return !(WPDeviceIdentification.isiPad() && !todoTours.isEmpty && indexPath.row == 0)
        case .completed:
            return true
        }
    }

    func tours(at section: Int) -> [QuickStartTour] {
        guard let section = Sections(rawValue: section) else {
            return []
        }

        switch section {
        case .todo:
            return todoTours
        case .completed:
            return completedSectionCollapse ? completedTours : []
        }
    }

    func isCompleted(tour: QuickStartTour) -> Bool {
        return completedToursKeys.contains(tour.key)
    }

    func tableView(_ tableView: UITableView, reloadCompletedSection collapsing: Bool) {
        var indexPaths: [IndexPath] = []
        for (index, _) in completedTours.enumerated() {
            indexPaths.append(IndexPath(row: index, section: Sections.completed.rawValue))
        }

        tableView.perform(update: { tableView in
            if collapsing {
                tableView.insertRows(at: indexPaths, with: .fade)
            } else {
                tableView.deleteRows(at: indexPaths, with: .fade)
            }
        })

        didTapHeader(collapsing)
    }

    func tableView(_ tableView: UITableView, completeTourAt indexPath: IndexPath) {
        let tour = todoTours[indexPath.row]
        todoTours.remove(at: indexPath.row)
        completedTours.append(tour)
        completedToursKeys.insert(tour.key)

        WPAnalytics.track(.quickStartListItemSkipped,
                          withProperties: ["task_name": tour.analyticsKey])

        tableView.perform(update: { tableView in
            tableView.deleteRows(at: [indexPath], with: .automatic)
            let sections = IndexSet(integer: Sections.completed.rawValue)
            tableView.reloadSections(sections, with: .fade)
        }) { [weak self] tableView, _ in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                if self.shouldShowCompleteTasksScreen() {
                    self.didTapHeader(self.completedSectionCollapse)
                }
                QuickStartTourGuide.shared.complete(tour: tour, for: self.blog, postNotification: false)
                let sections = IndexSet(integer: Sections.todo.rawValue)
                tableView.reloadSections(sections, with: .automatic)
            }
        }
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

private enum Sections: Int, CaseIterable {
    static let footerHeight: CGFloat = 20.0
    static let headerHeight: CGFloat = 44.0
    static let iPadTopInset: CGFloat = 36.0

    case todo
    case completed
}
