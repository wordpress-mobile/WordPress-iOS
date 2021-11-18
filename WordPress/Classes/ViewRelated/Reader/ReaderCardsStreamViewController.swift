import Foundation

class ReaderCardsStreamViewController: ReaderStreamViewController {
    private let readerCardTopicsIdentifier = "ReaderTopicsCell"
    private let readerCardSitesIdentifier = "ReaderSitesCell"

    /// Page number used for Analytics purpose
    private var page = 1

    /// Refresh counter used to for random posts on pull to refresh
    private var refreshCount = 0

    private var cards: [ReaderCard]? {
        content.content as? [ReaderCard]
    }

    lazy var cardsService: ReaderCardService = {
        return ReaderCardService()
    }()

    /// Tracks whether or not we should force sync
    /// This is set to true after the Reader Manage view is dismissed
    private var shouldForceRefresh = false

    private lazy var selectInterestsViewController: ReaderSelectInterestsViewController = {
        let title = NSLocalizedString("Discover and follow blogs you love", comment: "Reader select interests title label text")
        let subtitle = NSLocalizedString("Choose your topics", comment: "Reader select interests subtitle label text")
        let buttonTitleEnabled = NSLocalizedString("Done", comment: "Reader select interests next button enabled title text")
        let buttonTitleDisabled = NSLocalizedString("Select a few to continue", comment: "Reader select interests next button disabled title text")
        let loading = NSLocalizedString("Finding blogs and stories you’ll love...", comment: "Label displayed to the user while loading their selected interests")

        let configuration = ReaderSelectInterestsConfiguration(
            title: title,
            subtitle: subtitle,
            buttonTitle: (enabled: buttonTitleEnabled, disabled: buttonTitleDisabled),
            loading: loading
        )

        return ReaderSelectInterestsViewController(configuration: configuration)
    }()

    /// Whether the current view controller is visible
    private var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ReaderWelcomeBanner.displayIfNeeded(in: tableView)

        tableView.register(ReaderTopicsCardCell.defaultNib, forCellReuseIdentifier: readerCardTopicsIdentifier)
        tableView.register(ReaderSitesCardCell.self, forCellReuseIdentifier: readerCardSitesIdentifier)

        addObservers()
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
            guard let post = card.post else {
                return UITableViewCell()
            }
            return cell(for: post, at: indexPath)
        case .topics:
            return cell(for: card.topicsArray)
        case .sites:
            return cell(for: card.sitesArray)
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

    func cell(for sites: [ReaderSiteTopic]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: readerCardSitesIdentifier) as! ReaderSitesCardCell
        cell.configure(sites)
        cell.delegate = self
        return cell
    }

    private func isTableViewAtTheTop() -> Bool {
        return tableView.contentOffset.y == 0
    }

    @objc private func reload(_ notification: Foundation.Notification) {
        tableView.reloadData()
    }

    // MARK: - Sync

    override func fetch(for topic: ReaderAbstractTopic, success: @escaping ((Int, Bool) -> Void), failure: @escaping ((Error?) -> Void)) {
        page = 1
        refreshCount += 1

        cardsService.fetch(isFirstPage: true, refreshCount: refreshCount, success: { [weak self] cardsCount, hasMore in
            self?.trackContentPresented()
            success(cardsCount, hasMore)
        }, failure: { [weak self] error in
            self?.trackContentPresented()
            failure(error)
        })
    }

    override func loadMoreItems(_ success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        footerView.showSpinner(true)

        page += 1
        WPAnalytics.trackReader(.readerDiscoverPaginated, properties: ["page": page])

        cardsService.fetch(isFirstPage: false, success: { _, hasMore in
            success?(hasMore)
        }, failure: { error in
            guard let error = error else {
                return
            }

            failure?(error as NSError)
        })
    }

    override var topicPostsCount: Int {
        return cards?.count ?? 0
    }

    override func syncIfAppropriate(forceSync: Bool = false) {
        // Only sync if the tableview is at the top, otherwise this will change tableview's offset
        if isTableViewAtTheTop() {
            super.syncIfAppropriate(forceSync: forceSync)
        }
    }

    /// Track when the API returned the cards and the user is still on the screen
    /// This is used to create a funnel to check if users are leaving the screen
    /// before the API response
    private func trackContentPresented() {
        DispatchQueue.main.async {
            guard self.isVisible else {
                return
            }

            WPAnalytics.track(.readerDiscoverContentPresented)
        }
    }

    // MARK: - TableViewHandler

    override func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderCard.classNameWithoutNamespaces())
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest(ascending: true)
        return fetchRequest
    }

    override func predicateForFetchRequest() -> NSPredicate {
        return NSPredicate(format: "post != NULL OR topics.@count != 0 OR sites.@count != 0")
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

    private func addObservers() {

        // Listens for when the reader manage view controller is dismissed
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(manageControllerWasDismissed(_:)),
                                               name: .readerManageControllerWasDismissed,
                                               object: nil)

        // Listens for when a site is blocked
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(siteBlocked(_:)),
                                               name: .ReaderSiteBlocked,
                                               object: nil)
    }

    @objc private func manageControllerWasDismissed(_ notification: Foundation.Notification) {
        shouldForceRefresh = true
        self.displaySelectInterestsIfNeeded()
    }

    /// Update the post card when a site is blocked from post details.
    ///
    @objc private func siteBlocked(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let post = userInfo[ReaderNotificationKeys.post] as? ReaderPost,
              let posts = content.content as? [ReaderCard], // let posts = cards
              let contentPost = posts.first(where: { $0.post?.postID == post.postID }),
              let indexPath = content.indexPath(forObject: contentPost) else {
            return
        }

        super.syncIfAppropriate(forceSync: true)
        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)
    }
}

// MARK: - Select Interests Display
private extension ReaderCardsStreamViewController {
    func displaySelectInterestsIfNeeded() {
        selectInterestsViewController.userIsFollowingTopics { [unowned self] isFollowing in
            if isFollowing {
                self.hideSelectInterestsView()
            } else {
                self.showSelectInterestsView()
            }
        }
    }

    func hideSelectInterestsView() {
        guard selectInterestsViewController.parent != nil else {
            if shouldForceRefresh {
                scrollViewToTop()
                displayLoadingStream()
                super.syncIfAppropriate(forceSync: true)
                shouldForceRefresh = false
            }

            return
        }

        scrollViewToTop()
        displayLoadingStream()
        super.syncIfAppropriate(forceSync: true)

        UIView.animate(withDuration: 0.2, animations: {
            self.selectInterestsViewController.view.alpha = 0
        }) { [unowned self] _ in
            self.selectInterestsViewController.remove()
            self.selectInterestsViewController.view.alpha = 1
        }
    }

    func showSelectInterestsView() {
        guard selectInterestsViewController.parent == nil else {
            return
        }

        selectInterestsViewController.view.frame = self.view.bounds
        self.add(selectInterestsViewController)

        selectInterestsViewController.didSaveInterests = { [unowned self] _ in
            self.hideSelectInterestsView()
        }
    }
}

// MARK: - ReaderTopicsTableCardCellDelegate

extension ReaderCardsStreamViewController: ReaderTopicsTableCardCellDelegate {
    func didSelect(topic: ReaderAbstractTopic) {
        if topic as? ReaderTagTopic != nil {
            WPAnalytics.trackReader(.readerDiscoverTopicTapped)

            let topicStreamViewController = ReaderStreamViewController.controllerWithTopic(topic)
            navigationController?.pushViewController(topicStreamViewController, animated: true)
        } else if let siteTopic = topic as? ReaderSiteTopic {
            var properties = [String: Any]()
            properties[WPAppAnalyticsKeyBlogID] = siteTopic.siteID
            WPAnalytics.trackReader(.readerSuggestedSiteVisited, properties: properties)

            let topicStreamViewController = ReaderStreamViewController.controllerWithSiteID(siteTopic.siteID, isFeed: false)
            navigationController?.pushViewController(topicStreamViewController, animated: true)
        }
    }
}

// MARK: - ReaderSitesCardCellDelegate

extension ReaderCardsStreamViewController: ReaderSitesCardCellDelegate {
    func handleFollowActionForTopic(_ topic: ReaderAbstractTopic, for cell: ReaderSitesCardCell) {
        toggleFollowingForTopic(topic) { success in
            cell.didToggleFollowing(topic, with: success)
        }
    }
}
