import UIKit

class ReaderTabView: UIView {

    private let mainStackView: UIStackView
    private let tabBar: FilterTabBar
    private let containerView: UIView

    private let viewModel: ReaderTabViewModel

    private var filteredTabs: [(index: Int, topic: ReaderAbstractTopic)] = []
    private var previouslySelectedIndex: Int = 0

    private var discoverIndex: Int? {
        return tabBar.items.firstIndex(where: { ($0 as? ReaderTabItem)?.content.topicType == .discover })
    }

    private var p2Index: Int? {
        return tabBar.items.firstIndex(where: { (($0 as? ReaderTabItem)?.content.topic as? ReaderTeamTopic)?.organizationID == SiteOrganizationType.p2.rawValue })
    }

    init(viewModel: ReaderTabViewModel) {
        mainStackView = UIStackView()
        tabBar = FilterTabBar()
        containerView = UIView()

        self.viewModel = viewModel

        super.init(frame: .zero)

        viewModel.didSelectIndex = { [weak self] index in
            self?.tabBar.setSelectedIndex(index)
        }

        viewModel.onTabBarItemsDidChange { [weak self] tabItems, index in
            self?.tabBar.items = tabItems
            self?.tabBar.setSelectedIndex(index)
            self?.configureTabBarElements()
            self?.addContentToContainerView()
        }

        setupViewElements()

        NotificationCenter.default.addObserver(self, selector: #selector(topicUnfollowed(_:)), name: .ReaderTopicUnfollowed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(siteFollowed(_:)), name: .ReaderSiteFollowed, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - UI setup

extension ReaderTabView {

    private func setupViewElements() {
        backgroundColor = .filterBarBackground
        setupMainStackView()
        setupTabBar()
        activateConstraints()
    }

    private func setupMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        addSubview(mainStackView)
        mainStackView.addArrangedSubview(tabBar)
        mainStackView.addArrangedSubview(containerView)
    }

    private func setupTabBar() {
        tabBar.tabBarHeight = Appearance.barHeight
        WPStyleGuide.configureFilterTabBar(tabBar)
        tabBar.addTarget(self, action: #selector(selectedTabDidChange(_:)), for: .valueChanged)
        viewModel.fetchReaderMenu()
    }

    private func configureTabBarElements() {
        previouslySelectedIndex = tabBar.selectedIndex
    }

    private func setupHorizontalDivider(_ divider: UIView) {
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = Appearance.dividerColor
    }

    private func addContentToContainerView() {
        guard let controller = self.next as? UIViewController,
            let childController = viewModel.makeChildContentViewController(at: tabBar.selectedIndex) else {
                return
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false
        childController.view.translatesAutoresizingMaskIntoConstraints = false

        controller.children.forEach {
            $0.remove()
        }
        controller.add(childController)
        containerView.pinSubviewToAllEdges(childController.view)

        if viewModel.shouldShowCommentSpotlight {
            let title = NSLocalizedString("Comment to start making connections.", comment: "Hint for users to grow their audience by commenting on other blogs.")
            childController.displayNotice(title: title)
        }
    }

    private func activateConstraints() {
        pinSubviewToAllEdges(mainStackView)
    }

    func applyFilter(for selectedTopic: ReaderAbstractTopic?) {
        guard let selectedTopic = selectedTopic else {
            return
        }

        let selectedIndex = self.tabBar.selectedIndex

        // Remove any filters for selected index, then add new filter to array.
        self.filteredTabs.removeAll(where: { $0.index == selectedIndex })
        self.filteredTabs.append((index: selectedIndex, topic: selectedTopic))
    }
}

// MARK: - Actions

private extension ReaderTabView {

    /// Tab bar
    @objc func selectedTabDidChange(_ tabBar: FilterTabBar) {

        // If the tab was previously filtered, refilter it.
        // Otherwise reset the filter.
        if let existingFilter = filteredTabs.first(where: { $0.index == tabBar.selectedIndex }) {

            if previouslySelectedIndex == discoverIndex {
                // Reset the container view to show a feed's content.
                addContentToContainerView()
            }

            viewModel.setFilterContent(topic: existingFilter.topic)
        } else {
            addContentToContainerView()
        }

        previouslySelectedIndex = tabBar.selectedIndex

        viewModel.showTab(at: tabBar.selectedIndex)
    }

    @objc func topicUnfollowed(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let topic = userInfo[ReaderNotificationKeys.topic] as? ReaderAbstractTopic,
              let existingFilter = filteredTabs.first(where: { $0.topic == topic }) else {
            return
        }

        filteredTabs.removeAll(where: { $0 == existingFilter })
    }

    @objc func siteFollowed(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let site = userInfo[ReaderNotificationKeys.topic] as? ReaderSiteTopic,
              site.organizationType == .p2,
              p2Index == nil else {
            return
        }

        // If a P2 is followed but the P2 tab is not in the Reader tab bar,
        // refresh the Reader menu to display it.
        viewModel.fetchReaderMenu()
    }

}

// MARK: - Appearance

private extension ReaderTabView {

    enum Appearance {
        static let barHeight: CGFloat = 48
        static let dividerColor: UIColor = .divider
    }
}
