import UIKit


class ReaderTabView: UIView {

    private let mainStackView: UIStackView
    private let containerView: UIView
    private let buttonContainer: UIView
    private lazy var navigationMenu: UIView = {
        if !viewModel.itemsLoaded {
            viewModel.fetchReaderMenu()
        }
        let view = UIView.embedSwiftUIView(ReaderNavigationMenu(viewModel: viewModel,
                                                                selectedItem: viewModel.tabItems[safe: viewModel.selectedIndex]))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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
        NSLayoutConstraint.activate([
            navigationMenu.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 12.0),
            navigationMenu.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -16.0),
            navigationMenu.topAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: 8.0),
            navigationMenu.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: -8.0),
            buttonContainer.topAnchor.constraint(equalTo: safeTopAnchor),
            buttonContainer.leadingAnchor.constraint(equalTo: safeLeadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: safeTrailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
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
    }
}
