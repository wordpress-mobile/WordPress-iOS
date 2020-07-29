import Foundation

class ReaderCardsStreamViewController: ReaderStreamViewController {
    private let readerCardTopicsIdentifier = "ReaderTopicsCell"

    private var cards: [ReaderCard]? {
        content.content as? [ReaderCard]
    }

    lazy var cardsService: ReaderCardService = {
        return ReaderCardService()
    }()

    // Select Interests
    private lazy var interestsCoordinator: ReaderSelectInterestsCoordinator = {
        return ReaderSelectInterestsCoordinator()
    }()

    private var selectInterestsViewController: ReaderSelectInterestsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        ReaderWelcomeBanner.displayIfNeeded(in: tableView)
        tableView.register(ReaderTopicsCardCell.self, forCellReuseIdentifier: readerCardTopicsIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        displaySelectInterestsIfNeeded()
    }

    // MARK: - TableView Related

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let card = cards?[indexPath.row] else {
            return UITableViewCell()
        }

        switch card.type {
        case .post:
            return cell(for: card.post!, at: indexPath)
        case .topics:
            return cell(for: card.topicsArray)
        case .unknown:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let posts = content.content as? [ReaderCard], let post = posts[indexPath.row].post {
            didSelectPost(post, at: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

        if let posts = content.content as? [ReaderCard], let post = posts[indexPath.row].post {
            bumpRenderTracker(post)
        }
    }

    func cell(for interests: [ReaderTagTopic]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: readerCardTopicsIdentifier) as! ReaderTopicsCardCell
        cell.configure(interests)
        cell.delegate = self
        return cell
    }

    private func isTableViewAtTheTop() -> Bool {
        return tableView.contentOffset.y == 0
    }

    // MARK: - Sync

    override func fetch(for topic: ReaderAbstractTopic, success: @escaping ((Int, Bool) -> Void), failure: @escaping ((Error?) -> Void)) {
        cardsService.fetch(isFirstPage: true, success: success, failure: failure)
    }

    override func loadMoreItems(_ success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        footerView.showSpinner(true)

        cardsService.fetch(isFirstPage: false, success: { _, hasMore in
            success?(hasMore)
        }, failure: { error in
            guard let error = error else {
                return
            }

            failure?(error as NSError)
        })
    }

    override func syncIfAppropriate() {
        // Only sync if the tableview is at the top, otherwise this will change tableview's offset
        if isTableViewAtTheTop() {
            super.syncIfAppropriate()
        }
    }

    // MARK: - TableViewHandler

    override func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderCard.classNameWithoutNamespaces())
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest(ascending: true)
        return fetchRequest
    }

    override func predicateForFetchRequest() -> NSPredicate {
        return NSPredicate(format: "post != NULL OR topics.@count != 0")
    }

    /// Convenience method for instantiating an instance of ReaderCardsStreamViewController
    /// for a existing topic.
    ///
    /// - Parameters:
    ///     - topic: Any subclass of ReaderAbstractTopic
    ///
    /// - Returns: An instance of the controller
    ///
    class func controller(topic: ReaderAbstractTopic) -> ReaderCardsStreamViewController {
        let controller = ReaderCardsStreamViewController()
        controller.readerTopic = topic
        return controller
    }
}

// MARK: - Suggested Topics Delegate

extension ReaderCardsStreamViewController: ReaderTopicsCardCellDelegate {
    func didSelect(topic: ReaderTagTopic) {
        let topicStreamViewController = ReaderStreamViewController.controllerWithTopic(topic)
        navigationController?.pushViewController(topicStreamViewController, animated: true)
    }
}

// MARK: - Select Interests Display
private extension ReaderCardsStreamViewController {
    func displaySelectInterestsIfNeeded() {
        if self.selectInterestsViewController != nil {
            showSelectInterestsViewIfNeeded()
            return
        }

        // If we're not showing the select interests view, check to see if we should
        interestsCoordinator.shouldDisplay { [unowned self] shouldDisplay in
            if shouldDisplay {
                self.makeSelectInterestsViewControllerIfNeeded()
                self.showSelectInterestsViewIfNeeded()
            }
        }
    }

    func showSelectInterestsViewIfNeeded() {
        guard let controller = selectInterestsViewController else {
            return
        }

        // Using duration zero to prevent the screen from blinking
        UIView.animate(withDuration: 0) {
            controller.view.frame = self.view.bounds
            self.add(controller)
        }
    }

    func makeSelectInterestsViewControllerIfNeeded() {
        if selectInterestsViewController != nil {
            return
        }

        let controller = ReaderSelectInterestsViewController()
        controller.didSaveInterests = { [unowned self] in
            guard let controller = self.selectInterestsViewController else {
                return
            }

            UIView.animate(withDuration: 0.2, animations: {
                controller.view.alpha = 0.0
            }) { [unowned self] _ in
                controller.remove()
                self.selectInterestsViewController = nil
            }
        }

        selectInterestsViewController = controller
    }
}
