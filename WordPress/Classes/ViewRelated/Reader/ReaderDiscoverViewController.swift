import Foundation
import UIKit
import Combine

class ReaderDiscoverViewController: UIViewController, ReaderDiscoverHeaderViewDelegate, ReaderContentViewController {
    private let headerView = ReaderDiscoverHeaderView()
    private var selectedTag: ReaderDiscoverTag = .recommended
    private let topic: ReaderAbstractTopic
    private var streamVC: ReaderStreamViewController?

    init(topic: ReaderAbstractTopic) {
        wpAssert(ReaderHelpers.topicIsDiscover(topic))
        self.topic = topic
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigation()
        setupHeaderView()
        configureStream(ReaderDiscoverStreamViewController.controller(topic: topic))
    }

    private func setupNavigation() {
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupHeaderView() {
        headerView.configure(tags: [.recommended, .latest])
        headerView.setSelectedTag(selectedTag)
        headerView.delegate = self
    }

    private func configureStream(_ streamVC: ReaderStreamViewController) {
        self.streamVC = streamVC

        addChild(streamVC)
        view.addSubview(streamVC.view)
        streamVC.view.pinEdges()
        streamVC.didMove(toParent: self)

        if FeatureFlag.readerReset.enabled {
            streamVC.setHeaderView(headerView)
        }
    }

    // MARK: - ReaderContentViewController (Deprecated)

    func setContent(_ content: ReaderContent) {
        streamVC?.setContent(content)
    }

    // MARK: - ReaderDiscoverHeaderViewDelegate

    func readerDiscoverHeaderView(_ view: ReaderDiscoverHeaderView, didChangeSelection selection: ReaderDiscoverTag) {
        print("sel:", selection)
    }
}

private class ReaderDiscoverStreamViewController: ReaderStreamViewController {
    private let readerCardTopicsIdentifier = "ReaderTopicsCell"
    private let readerCardSitesIdentifier = "ReaderSitesCell"

    /// Page number used for Analytics purpose
    private var page = 1

    /// Refresh counter used to for random posts on pull to refresh
    private var refreshCount = 0

    private var cards: [ReaderCard]? {
        content.content as? [ReaderCard]
    }

    private lazy var cardsService = ReaderCardService()

    /// Whether the current view controller is visible
    private var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        // register table view cells specific to this controller as early as possible.
        // the superclass might trigger `layoutIfNeeded` from its `viewDidLoad`, and we want to make sure that
        // all the cell types have been registered by that time.
        // see: https://github.com/wordpress-mobile/WordPress-iOS/pull/23368
        tableView.register(ReaderTopicsCardCell.defaultNib, forCellReuseIdentifier: readerCardTopicsIdentifier)
        tableView.register(ReaderSitesCardCell.self, forCellReuseIdentifier: readerCardSitesIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displaySelectInterestsIfNeeded()
    }

    // MARK: - UITableView

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let card = cards?[indexPath.row] else {
            return UITableViewCell()
        }

        switch card.type {
        case .post:
            guard let post = card.post else {
                return UITableViewCell()
            }

            let shouldShowSeparator: Bool = {
                guard let cards,
                      let nextCard = cards[safe: indexPath.row + 1] else {
                    return true
                }
                return !nextCard.isRecommendationCard
            }()
            return cell(for: post, at: indexPath, showsSeparator: shouldShowSeparator)

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
        hideSeparator(for: cell)
        return cell
    }

    func cell(for sites: [ReaderSiteTopic]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: readerCardSitesIdentifier) as! ReaderSitesCardCell
        cell.configure(sites)
        cell.delegate = self
        hideSeparator(for: cell)
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

    override func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>? {
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
    class func controller(topic: ReaderAbstractTopic) -> ReaderDiscoverStreamViewController {
        let controller = ReaderDiscoverStreamViewController()
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
private extension ReaderDiscoverStreamViewController {
    func displaySelectInterestsIfNeeded() {
        selectInterestsViewController.userIsFollowingTopics { [weak self] isFollowing in
            guard let self else {
                return
            }
            if isFollowing {
                self.hideSelectInterestsView()
            } else {
                self.showSelectInterestsView()
            }
        }
    }
}

// MARK: - ReaderTopicsTableCardCellDelegate

extension ReaderDiscoverStreamViewController: ReaderTopicsTableCardCellDelegate {
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

extension ReaderDiscoverStreamViewController: ReaderSitesCardCellDelegate {
    func handleFollowActionForTopic(_ topic: ReaderAbstractTopic, for cell: ReaderSitesCardCell) {
        toggleFollowingForTopic(topic) { success in
            cell.didToggleFollowing(topic, with: success)
        }
    }
}
