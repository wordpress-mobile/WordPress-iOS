import UIKit

class ReaderTabView: UIView {

    private let mainStackView: UIStackView
    private var mainStackViewTopAnchor: NSLayoutConstraint?
    private let containerView: UIView
    private let buttonContainer: UIView
    private lazy var navigationMenu: UIView = {
        if !viewModel.itemsLoaded {
            viewModel.fetchReaderMenu()
        }
        let view = UIView.embedSwiftUIView(ReaderNavigationMenu(viewModel: viewModel))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var isMenuHidden = false

    private let viewModel: ReaderTabViewModel

    private var filteredTabs: [(index: Int, topic: ReaderAbstractTopic)] = []
    private var previouslySelectedIndex: Int = 0

    private var discoverIndex: Int? {
        return viewModel.tabItems.firstIndex(where: { $0.content.topicType == .discover })
    }

    private var p2Index: Int? {
        return viewModel.tabItems.firstIndex(where: { ($0.content.topic as? ReaderTeamTopic)?.organizationID == SiteOrganizationType.p2.rawValue })
    }

    init(viewModel: ReaderTabViewModel) {
        mainStackView = UIStackView()
        containerView = UIView()
        buttonContainer = UIView()

        self.viewModel = viewModel

        super.init(frame: .zero)

        viewModel.didSelectIndex = { [weak self] index in
            guard let self else {
                return
            }

            if let existingFilter = filteredTabs.first(where: { $0.index == index }) {
                if previouslySelectedIndex == discoverIndex {
                    addContentToContainerView(index: index)
                }
                viewModel.setFilterContent(topic: existingFilter.topic)
            } else {
                addContentToContainerView(index: index)
            }
            previouslySelectedIndex = index
        }

        viewModel.onTabBarItemsDidChange { [weak self] tabItems, index in
            self?.addContentToContainerView(index: index)
        }

        setupViewElements()
        viewModel.fetchReaderMenu()

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
        backgroundColor = UIColor(light: .white, dark: .black)
        setupButtonContainer()
        setupMainStackView()
        activateConstraints()
    }

    private func setupButtonContainer() {
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(navigationMenu)
    }

    private func setupMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        addSubview(buttonContainer)
        addSubview(mainStackView)
        mainStackView.addArrangedSubview(containerView)
    }

    private func setupHorizontalDivider(_ divider: UIView) {
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = Appearance.dividerColor
    }

    private func addContentToContainerView(index: Int) {
        guard let controller = self.next as? UIViewController,
            let childController = viewModel.makeChildContentViewController(at: index) else {
                return
        }

        if let childController = childController as? ReaderStreamViewController {
            childController.navigationMenuDelegate = self
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
        mainStackViewTopAnchor = mainStackView.topAnchor.constraint(equalTo: buttonContainer.bottomAnchor)
        guard let mainStackViewTopAnchor else { return }
        NSLayoutConstraint.activate([
            navigationMenu.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 12.0),
            navigationMenu.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -16.0),
            navigationMenu.topAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: 8.0),
            navigationMenu.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: -8.0),
            buttonContainer.topAnchor.constraint(equalTo: safeTopAnchor),
            buttonContainer.leadingAnchor.constraint(equalTo: safeLeadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: safeTrailingAnchor),
            mainStackViewTopAnchor,
            mainStackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: safeLeadingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: safeBottomAnchor),
        ])
    }

    func applyFilter(for selectedTopic: ReaderAbstractTopic?) {
        guard let selectedTopic = selectedTopic else {
            return
        }

        let selectedIndex = viewModel.selectedIndex

        // Remove any filters for selected index, then add new filter to array.
        self.filteredTabs.removeAll(where: { $0.index == selectedIndex })
        self.filteredTabs.append((index: selectedIndex, topic: selectedTopic))
    }

    /// Disables the `scrollsToTop` property for the scroll views created from SwiftUI.
    /// To preserve the native scroll-to-top behavior when the status bar is tapped, there
    func disableScrollsToTop() {
        var viewsToTraverse = navigationMenu.subviews
        while viewsToTraverse.count > 0 {
            let subview = viewsToTraverse.removeFirst()
            if let scrollView = subview as? UIScrollView {
                scrollView.scrollsToTop = false
            }
            viewsToTraverse.append(contentsOf: subview.subviews)
        }
    }

    private func updateMenuDisplay(hidden: Bool) {
        guard isMenuHidden != hidden else { return }

        isMenuHidden = hidden
        mainStackViewTopAnchor?.constant = hidden ? -buttonContainer.frame.height : 0
        UIView.animate(withDuration: Appearance.hideShowBarDuration) {
            self.layoutIfNeeded()
        }
    }
}

// MARK: - Actions

private extension ReaderTabView {

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
        static let hideShowBarDuration: CGFloat = 0.2
    }
}

// MARK: - ReaderNavigationMenuDelegate

extension ReaderTabView: ReaderNavigationMenuDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView, velocity: CGPoint) {
        let isContentOffsetNearTop = scrollView.contentOffset.y < scrollView.frame.height / 2
        let isContentOffsetAtTop = scrollView.contentOffset.y == .zero
        let isUserScrollingDown = velocity.y < -400
        let isUserScrollingUp = velocity.y > 400

        if !isMenuHidden && !isContentOffsetNearTop && isUserScrollingDown {
            updateMenuDisplay(hidden: true)
        }

        if isMenuHidden && isUserScrollingUp {
            updateMenuDisplay(hidden: false)
        }

        // Handles the native scroll-to-top behavior (by tapping the status bar).
        // Somehow the `scrollViewDidScrollToTop` method is not called in the view controller
        // containing the scroll view, so we'll need to put a custom logic here instead.
        if isMenuHidden && isContentOffsetAtTop {
            updateMenuDisplay(hidden: false)
        }

        // Accounts for a user scrolling slowly enough to not trigger displaying the menu near the top of the content
        if isMenuHidden && isContentOffsetNearTop && velocity.y > 0 {
            updateMenuDisplay(hidden: false)
        }

    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let isTargetContentNearTop = targetContentOffset.pointee.y < scrollView.frame.height / 2

        // Accounts for the case where a user quickly swipes the scroll view without holding their
        // finger on it.
        // Note: velocity here is opposite of the velocity in `scrollViewDidScroll`. Positive values
        // are scrolling down. The scale is also much different.
        if !isMenuHidden && !isTargetContentNearTop && velocity.y > 0.5 {
            updateMenuDisplay(hidden: true)
        }
    }

    func didTapDiscoverBlogs() {
        guard let discoverIndex else {
            return
        }
        viewModel.showTab(at: discoverIndex)
    }

    func didScrollToTop() {
        updateMenuDisplay(hidden: false)
    }

}
