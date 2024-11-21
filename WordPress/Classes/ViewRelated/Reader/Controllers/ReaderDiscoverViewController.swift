import Foundation
import UIKit
import Combine
import WordPressKit
import WordPressShared

class ReaderDiscoverViewController: UIViewController, ReaderDiscoverHeaderViewDelegate {
    private let headerView = ReaderDiscoverHeaderView()
    private var selectedChannel: ReaderDiscoverChannel = .recommended
    private let topic: ReaderAbstractTopic
    private var streamVC: ReaderStreamViewController?
    private weak var selectInterestsVC: ReaderSelectInterestsViewController?
    private let selectInterestsCoordinator = ReaderSelectInterestsCoordinator()
    private let tags: ManagedObjectsObserver<ReaderTagTopic>
    private let viewContext: NSManagedObjectContext
    private var cancellables: [AnyCancellable] = []

    init(topic: ReaderAbstractTopic) {
        wpAssert(ReaderHelpers.topicIsDiscover(topic))
        self.viewContext = ContextManager.shared.mainContext
        self.topic = topic
        self.tags = ManagedObjectsObserver(
            predicate: ReaderSidebarTagsSection.predicate,
            sortDescriptors: [SortDescriptor(\.title, order: .forward)],
            context: viewContext
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigation()
        setupHeaderView()

        configureStream(for: selectedChannel)

        showSelectInterestsIfNeeded()
    }

    private func setupNavigation() {
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupHeaderView() {
        tags.$objects.sink { [weak self] tags in
            self?.configureHeader(tags: tags)
        }.store(in: &cancellables)

        headerView.delegate = self
    }

    private func configureHeader(tags: [ReaderTagTopic]) {
        let channels = tags
            .filter { $0.slug != ReaderTagTopic.dailyPromptTag }
            .map(ReaderDiscoverChannel.tag)

        headerView.configure(channels: [.recommended, .firstPosts, .latest, .dailyPrompts] + channels)
        headerView.setSelectedChannel(selectedChannel)
    }

    // MARK: - Selected Stream

    private func configureStream(for channel: ReaderDiscoverChannel) {
        showStreamViewController(makeViewController(for: channel))
    }

    private func makeViewController(for channel: ReaderDiscoverChannel) -> ReaderStreamViewController {
        switch channel {
        case .recommended:
            ReaderDiscoverStreamViewController(topic: topic)
        case .firstPosts:
            ReaderDiscoverStreamViewController(topic: topic, stream: .firstPosts, sorting: .date)
        case .latest:
            ReaderDiscoverStreamViewController(topic: topic, sorting: .date)
        case .dailyPrompts:
            ReaderStreamViewController.controllerWithTagSlug(ReaderTagTopic.dailyPromptTag)
        case .tag(let tag):
            ReaderStreamViewController.controllerWithTopic(tag)
        }
    }

    private func showStreamViewController(_ streamVC: ReaderStreamViewController) {
        if let currentVC = self.streamVC {
            deleteCachedReaderCards()

            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }

        self.streamVC = streamVC

        // Important to set before `viewDidLoad`
        streamVC.isEmbeddedInDiscover = true
        streamVC.preferredTableHeaderView = headerView

        addChild(streamVC)
        view.addSubview(streamVC.view)
        streamVC.view.pinEdges()
        streamVC.didMove(toParent: self)

        navigationItem.titleView = streamVC.navigationItem.titleView // important
    }

    /// TODO: (tech-debt) the app currently stores the responses from the `/discover`
    /// entpoint (cards) in Core Data with no way to distinguish between the
    /// requests with different parameters like different sort. In order to
    /// address it, the app currently drops the previously cached responses
    /// when you change the streams.
    private func deleteCachedReaderCards() {
        ReaderCardService.removeAllCards()
    }

    // MARK: ReaderDiscoverHeaderViewDelegate

    func readerDiscoverHeaderView(_ view: ReaderDiscoverHeaderView, didChangeSelection selection: ReaderDiscoverChannel) {
        self.selectedChannel = selection
        configureStream(for: selection)
        WPAnalytics.track(.readerDiscoverChannelSelected, properties: selection.analyticsProperties)
    }

    // MARK: Select Interests

    private func showSelectInterestsIfNeeded() {
        guard !UserDefaults.standard.readerDidSelectInterestsKey else {
            return
        }
        selectInterestsCoordinator.isFollowingInterests { [weak self] isFollowing in
            if !isFollowing {
                self?.showSelectInterestsScreen()
            }
        }
    }

    private func showSelectInterestsScreen() {
        guard selectInterestsVC == nil else { return }

        let selectInterestsVC = ReaderSelectInterestsViewController(configuration: .discover)
        selectInterestsVC.isModalInPresentation = true
        selectInterestsVC.didSaveInterests = { [weak self] _ in
            self?.didSaveInterests()
        }
        present(selectInterestsVC, animated: true)
        self.selectInterestsVC = selectInterestsVC
    }

    private func didSaveInterests() {
        UserDefaults.standard.readerDidSelectInterestsKey = true

        guard selectInterestsVC != nil else { return }
        dismiss(animated: true) {
            if let streamVC = self.streamVC {
                streamVC.scrollViewToTop()
                streamVC.displayLoadingStream()
                streamVC.syncIfAppropriate(forceSync: true)
            }
        }
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

    private let cardsService: ReaderCardService

    /// Whether the current view controller is visible
    private var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }

    init(topic: ReaderAbstractTopic, stream: ReaderStream = .discover, sorting: ReaderSortingOption = .noSorting) {
        self.cardsService = ReaderCardService(stream: stream, sorting: sorting)

        super.init(nibName: nil, bundle: nil)

        self.readerTopic = topic

        // register table view cells specific to this controller as early as possible.
        // the superclass might trigger `layoutIfNeeded` from its `viewDidLoad`, and we want to make sure that
        // all the cell types have been registered by that time.
        // see: https://github.com/wordpress-mobile/WordPress-iOS/pull/23368
        tableView.register(ReaderRecommendedTagsCell.self, forCellReuseIdentifier: readerCardTopicsIdentifier)
        tableView.register(ReaderRecommendedSitesCell.self, forCellReuseIdentifier: readerCardSitesIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addObservers()
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
            return makeRecommendedTagsCell(for: card.topicsArray)
        case .sites:
            return makeRecommendedSitesCell(for: card.sitesArray)
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

    private func makeRecommendedTagsCell(for interests: [ReaderTagTopic]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: readerCardTopicsIdentifier) as! ReaderRecommendedTagsCell
        cell.configure(with: interests, delegate: self)
        hideSeparator(for: cell)
        return cell
    }

    private func makeRecommendedSitesCell(for sites: [ReaderSiteTopic]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: readerCardSitesIdentifier) as! ReaderRecommendedSitesCell
        cell.configure(with: sites, delegate: self)
        hideSeparator(for: cell)
        return cell
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
        footerView.isHidden = false

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
        if tableView.contentOffset.y <= 0 {
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

    private func addObservers() {
        // Listens for when a site is blocked
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(siteBlocked(_:)),
                                               name: .ReaderSiteBlocked,
                                               object: nil)
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

    override func getPost(at indexPath: IndexPath) -> ReaderPost? {
        guard let card: ReaderCard = content.object(at: indexPath) else {
            return nil
        }
        return card.post
    }
}

// MARK: - ReaderRecommendationsCellDelegate

extension ReaderDiscoverStreamViewController: ReaderRecommendationsCellDelegate {
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
