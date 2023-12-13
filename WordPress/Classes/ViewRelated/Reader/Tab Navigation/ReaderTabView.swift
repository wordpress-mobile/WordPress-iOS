import UIKit

class ReaderTabView: UIView {

    private let mainStackView: UIStackView
    private let containerView: UIView

    private let viewModel: ReaderTabViewModel

    private var filteredTabs: [(index: Int, topic: ReaderAbstractTopic)] = []
    private var previouslySelectedIndex: Int = 0

    private var discoverIndex: Int? {
        return 1 // TODO: Discover index
    }

    private var p2Index: Int? {
        return 2 // TODO: P2 index
    }

    init(viewModel: ReaderTabViewModel) {
        mainStackView = UIStackView()
        containerView = UIView()

        self.viewModel = viewModel

        super.init(frame: .zero)

        viewModel.onTabBarItemsDidChange { [weak self] tabItems, index in
            self?.addContentToContainerView()
        }

        setupViewElements()
        viewModel.fetchReaderMenu() // TODO: Temporary, remove later

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
        activateConstraints()
    }

    private func setupMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        addSubview(mainStackView)
        mainStackView.addArrangedSubview(containerView)
    }

    private func setupHorizontalDivider(_ divider: UIView) {
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = Appearance.dividerColor
    }

    private func addContentToContainerView() {
        guard let controller = self.next as? UIViewController,
            let childController = viewModel.makeChildContentViewController(at: 0) else { // TODO: Replace `0` with selected index
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

        let selectedIndex = 0 // TODO: Selected index according to selection

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
