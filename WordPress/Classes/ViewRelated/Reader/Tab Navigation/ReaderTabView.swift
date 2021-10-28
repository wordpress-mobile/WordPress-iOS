import UIKit


class ReaderTabView: UIView {

    private let mainStackView: UIStackView
    private let buttonsStackView: UIStackView
    private let tabBar: FilterTabBar
    private let filterButton: PostMetaButton
    private let resetFilterButton: UIButton
    private let horizontalDivider: UIView
    private let containerView: UIView
    private var loadingView: UIView?

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
        buttonsStackView = UIStackView()
        tabBar = FilterTabBar()
        filterButton = PostMetaButton(type: .custom)
        resetFilterButton = UIButton(type: .custom)
        horizontalDivider = UIView()
        containerView = UIView()

        self.viewModel = viewModel

        super.init(frame: .zero)

        viewModel.didSelectIndex = { [weak self] index in
            self?.tabBar.setSelectedIndex(index)
            self?.toggleButtonsView()
        }

        viewModel.onTabBarItemsDidChange { [weak self] tabItems, index in
            self?.tabBar.items = tabItems
            self?.tabBar.setSelectedIndex(index)
            self?.configureTabBarElements()
            self?.hideGhost()
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

    /// Call this method to set the title of the filter button
    private func setFilterButtonTitle(_ title: String) {
        WPStyleGuide.applyReaderFilterButtonTitle(filterButton, title: title)
    }

    private func setupViewElements() {
        backgroundColor = .filterBarBackground
        setupMainStackView()
        setupTabBar()
        setupButtonsView()
        setupFilterButton()
        setupResetFilterButton()
        setupHorizontalDivider(horizontalDivider)
        activateConstraints()
    }

    private func setupMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        addSubview(mainStackView)
        mainStackView.addArrangedSubview(tabBar)
        mainStackView.addArrangedSubview(buttonsStackView)
        mainStackView.addArrangedSubview(horizontalDivider)
        mainStackView.addArrangedSubview(containerView)
    }

    private func setupTabBar() {
        tabBar.tabBarHeight = Appearance.barHeight
        WPStyleGuide.configureFilterTabBar(tabBar)
        tabBar.addTarget(self, action: #selector(selectedTabDidChange(_:)), for: .valueChanged)
        viewModel.fetchReaderMenu()
    }

    private func configureTabBarElements() {
        guard let tabItem = tabBar.currentlySelectedItem as? ReaderTabItem else {
            return
        }

        previouslySelectedIndex = tabBar.selectedIndex
        buttonsStackView.isHidden = tabItem.shouldHideButtonsView
        horizontalDivider.isHidden = tabItem.shouldHideButtonsView
    }

    private func setupButtonsView() {
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.isLayoutMarginsRelativeArrangement = true
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .fill
        buttonsStackView.addArrangedSubview(filterButton)
        buttonsStackView.addArrangedSubview(resetFilterButton)
        buttonsStackView.isHidden = true
    }

    private func setupFilterButton() {
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.contentEdgeInsets = Appearance.filterButtonInsets
        filterButton.imageEdgeInsets = Appearance.filterButtonimageInsets
        filterButton.titleEdgeInsets = Appearance.filterButtonTitleInsets
        filterButton.contentHorizontalAlignment = .leading

        filterButton.titleLabel?.font = Appearance.filterButtonFont
        WPStyleGuide.applyReaderFilterButtonStyle(filterButton)
        setFilterButtonTitle(Appearance.defaultFilterButtonTitle)
        filterButton.addTarget(self, action: #selector(didTapFilterButton), for: .touchUpInside)
        filterButton.accessibilityIdentifier = Accessibility.filterButtonIdentifier
    }

    private func setupResetFilterButton() {
        resetFilterButton.translatesAutoresizingMaskIntoConstraints = false
        resetFilterButton.contentEdgeInsets = Appearance.resetButtonInsets
        WPStyleGuide.applyReaderResetFilterButtonStyle(resetFilterButton)
        resetFilterButton.addTarget(self, action: #selector(didTapResetFilterButton), for: .touchUpInside)
        resetFilterButton.isHidden = true
        resetFilterButton.accessibilityIdentifier = Accessibility.resetButtonIdentifier
        resetFilterButton.accessibilityLabel = Accessibility.resetFilterButtonLabel
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
        NSLayoutConstraint.activate([
            buttonsStackView.heightAnchor.constraint(equalToConstant: Appearance.barHeight),
            resetFilterButton.widthAnchor.constraint(equalToConstant: Appearance.resetButtonWidth),
            horizontalDivider.heightAnchor.constraint(equalToConstant: Appearance.dividerWidth),
            horizontalDivider.widthAnchor.constraint(equalTo: mainStackView.widthAnchor)
        ])
    }

    func applyFilter(for selectedTopic: ReaderAbstractTopic?) {
        guard let selectedTopic = selectedTopic else {
            return
        }

        let selectedIndex = self.tabBar.selectedIndex

        // Remove any filters for selected index, then add new filter to array.
        self.filteredTabs.removeAll(where: { $0.index == selectedIndex })
        self.filteredTabs.append((index: selectedIndex, topic: selectedTopic))

        self.resetFilterButton.isHidden = false
        self.setFilterButtonTitle(selectedTopic.title)
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

            resetFilterButton.isHidden = false
            setFilterButtonTitle(existingFilter.topic.title)
        } else {
            addContentToContainerView()
        }

        previouslySelectedIndex = tabBar.selectedIndex

        viewModel.showTab(at: tabBar.selectedIndex)
        toggleButtonsView()
    }

    func toggleButtonsView() {
        guard let tabItems = tabBar.items as? [ReaderTabItem] else {
            return
        }
        // hide/show buttons depending on the selected tab. Do not execute the animation if not necessary.
        guard buttonsStackView.isHidden != tabItems[tabBar.selectedIndex].shouldHideButtonsView else {
            return
        }
        let shouldHideButtons = tabItems[self.tabBar.selectedIndex].shouldHideButtonsView
        self.buttonsStackView.isHidden = shouldHideButtons
        self.horizontalDivider.isHidden = shouldHideButtons
    }

    /// Filter button
    @objc func didTapFilterButton() {
        /// Present from the image view to align to the left hand side
        viewModel.presentFilter(from: filterButton.imageView ?? filterButton) { [weak self] selectedTopic in
            guard let self = self else {
                return
            }
            self.applyFilter(for: selectedTopic)
        }
    }

    /// Reset filter button
    @objc func didTapResetFilterButton() {
        filteredTabs.removeAll(where: { $0.index == tabBar.selectedIndex })
        setFilterButtonTitle(Appearance.defaultFilterButtonTitle)
        resetFilterButton.isHidden = true
        guard let tabItem = tabBar.currentlySelectedItem as? ReaderTabItem else {
            return
        }
        viewModel.resetFilter(selectedItem: tabItem)
    }

    @objc func topicUnfollowed(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let topic = userInfo[ReaderNotificationKeys.topic] as? ReaderAbstractTopic,
              let existingFilter = filteredTabs.first(where: { $0.topic == topic }) else {
            return
        }

        filteredTabs.removeAll(where: { $0 == existingFilter })

        if existingFilter.index == tabBar.selectedIndex {
            didTapResetFilterButton()
        }

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


// MARK: - Ghost

private extension ReaderTabView {

    /// Build the ghost tab bar
    func makeGhostTabBar() -> FilterTabBar {
        let ghostTabBar = FilterTabBar()

        ghostTabBar.items = Appearance.ghostTabItems
        ghostTabBar.isUserInteractionEnabled = false
        ghostTabBar.tabBarHeight = Appearance.barHeight
        ghostTabBar.dividerColor = .clear

        return ghostTabBar
    }

    /// Show the ghost tab bar
    func showGhost() {
        let ghostTabBar = makeGhostTabBar()
        tabBar.addSubview(ghostTabBar)
        tabBar.pinSubviewToAllEdges(ghostTabBar)

        loadingView = ghostTabBar

        ghostTabBar.startGhostAnimation(style: GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                                                          beatStartColor: .placeholderElement,
                                                          beatEndColor: .placeholderElementFaded))

    }

    /// Hide the ghost tab bar
    func hideGhost() {
        loadingView?.stopGhostAnimation()
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    struct GhostTabItem: FilterTabBarItem {
        var title: String
        let accessibilityIdentifier = ""
    }
}

// MARK: - Appearance

private extension ReaderTabView {

    enum Appearance {
        static let barHeight: CGFloat = 48

        static let tabBarAnimationsDuration = 0.2

        static let defaultFilterButtonTitle = NSLocalizedString("Filter", comment: "Title of the filter button in the Reader")
        static let filterButtonMaxFontSize: CGFloat = 28.0
        static let filterButtonFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .regular)
        static let filterButtonInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        static let filterButtonimageInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        static let filterButtonTitleInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)

        static let resetButtonWidth: CGFloat = 32
        static let resetButtonInsets = UIEdgeInsets(top: 1, left: -4, bottom: -1, right: 4)

        static let dividerWidth: CGFloat = .hairlineBorderWidth
        static let dividerColor: UIColor = .divider
        // "ghost" titles are set to the default english titles, as they won't be visible anyway
        static let ghostTabItems = [GhostTabItem(title: "Following"), GhostTabItem(title: "Discover"), GhostTabItem(title: "Likes"), GhostTabItem(title: "Saved")]
    }
}


// MARK: - Accessibility

extension ReaderTabView {
    private enum Accessibility {
        static let filterButtonIdentifier = "ReaderFilterButton"
        static let resetButtonIdentifier = "ReaderResetButton"
        static let resetFilterButtonLabel = NSLocalizedString("Reset filter", comment: "Accessibility label for the reset filter button in the reader.")
    }
}
