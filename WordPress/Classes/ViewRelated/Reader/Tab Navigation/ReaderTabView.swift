import UIKit

class ReaderTabView: UIView {

    private let mainStackView: UIStackView
    private let buttonsStackView: UIStackView
    private let tabBar: FilterTabBar
    private let filterButton: PostMetaButton
    private let resetFilterButton: UIButton
    private let settingsButton: UIButton
    private let verticalDivider: UIView
    private let horizontalDivider: UIView
    private let containerView: UIView

    private let viewModel: ReaderTabViewModel

    init(viewModel: ReaderTabViewModel) {
        mainStackView = UIStackView()
        buttonsStackView = UIStackView()
        tabBar = FilterTabBar()
        filterButton = PostMetaButton(type: .custom)
        resetFilterButton = UIButton(type: .custom)
        settingsButton = UIButton(type: .custom)
        verticalDivider = UIView()
        horizontalDivider = UIView()
        containerView = UIView()

        self.viewModel = viewModel

        super.init(frame: .zero)
        setupViewElements()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI setup
extension ReaderTabView {

    /// Call this method to set the title of the filter button
    func setFilterButtonTitle(_ title: String) {
        WPStyleGuide.applyReaderFilterButtonTitle(filterButton, title: title)
    }

    private func setupViewElements() {
        backgroundColor = .filterBarBackground
        setupMainStackView()
        setupTabBar()
        setupButtonsView()
        setupFilterButton()
        setupResetFilterButton()
        setupDivider(verticalDivider)
        setupDivider(horizontalDivider)
        setupSettingsButton()
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

        viewModel.fetchReaderMenu() { [weak self] items in
            guard let items = items, let self = self else {
                return
            }
            self.populateTabBar(with: items)
            self.addContentToContainerView()
        }
    }

    private func populateTabBar(with items: [ReaderTabItem]) {
        tabBar.items = items
        guard let tabItem = tabBar.items[tabBar.selectedIndex] as? ReaderTabItem else {
            return
        }
        buttonsStackView.isHidden = tabItem.shouldHideButtonsView
        horizontalDivider.isHidden = tabItem.shouldHideButtonsView
    }

    private func setupButtonsView() {
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.isLayoutMarginsRelativeArrangement = true
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .center
        buttonsStackView.addArrangedSubview(filterButton)
        buttonsStackView.addArrangedSubview(resetFilterButton)
        let spacer = UIView()
        buttonsStackView.addArrangedSubview(spacer)
        buttonsStackView.addArrangedSubview(verticalDivider)
        buttonsStackView.addArrangedSubview(settingsButton)
    }

    private func setupFilterButton() {
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.contentEdgeInsets = Appearance.filterButtonInsets
        filterButton.imageEdgeInsets = Appearance.filterButtonimageInsets
        filterButton.titleEdgeInsets = Appearance.filterButtonTitleInsets

        filterButton.titleLabel?.font = Appearance.filterButtonFont
        WPStyleGuide.applyReaderFilterButtonStyle(filterButton)
        setFilterButtonTitle(Appearance.defaultFilterButtonTitle)
        filterButton.addTarget(self, action: #selector(didTapFilterButton), for: .touchUpInside)
    }

    private func setupResetFilterButton() {
        resetFilterButton.translatesAutoresizingMaskIntoConstraints = false
        resetFilterButton.contentEdgeInsets = Appearance.resetButtonInsets
        WPStyleGuide.applyReaderResetFilterButtonStyle(resetFilterButton)
        resetFilterButton.addTarget(self, action: #selector(didTapResetFilterButton), for: .touchUpInside)
        resetFilterButton.isHidden = true
    }

    private func setupDivider(_ divider: UIView) {
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = Appearance.dividerColor
    }

    private func setupSettingsButton() {
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(didTapSettingsButton), for: .touchUpInside)
        WPStyleGuide.applyReaderSettingsButtonStyle(settingsButton)
    }

    private func addContentToContainerView() {
        guard let controller = self.next as? UIViewController,
            let readerTabItem = tabBar.items[tabBar.selectedIndex] as? ReaderTabItem,
            let childController = viewModel.makeChildViewController(with: readerTabItem) else {
                return
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false
        childController.view.translatesAutoresizingMaskIntoConstraints = false

        controller.addChild(childController)

        containerView.addSubview(childController.view)
        containerView.pinSubviewToAllEdges(childController.view)
        childController.didMove(toParent: controller)
    }

    private func activateConstraints() {
        pinSubviewToAllEdges(mainStackView)
        NSLayoutConstraint.activate([
            buttonsStackView.heightAnchor.constraint(equalToConstant: Appearance.barHeight),
            resetFilterButton.widthAnchor.constraint(equalToConstant: Appearance.resetButtonWidth),
            verticalDivider.widthAnchor.constraint(equalToConstant: Appearance.dividerWidth),
            verticalDivider.heightAnchor.constraint(equalTo: buttonsStackView.heightAnchor,
                                                    multiplier: Appearance.verticalDividerHeightMultiplier),
            horizontalDivider.heightAnchor.constraint(equalToConstant: Appearance.dividerWidth),
            horizontalDivider.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: Appearance.settingsButtonWidth)
        ])
    }
}

// MARK: - Actions
extension ReaderTabView {
    /// Tab bar
    @objc private func selectedTabDidChange(_ tabBar: FilterTabBar) {
        guard let tabItems = tabBar.items as? [ReaderTabItem] else {
                return
        }
        self.viewModel.showTab(for: tabBar.items[tabBar.selectedIndex])
        // hide/show buttons depending on the selected tab. Do not execute the animation if not necessary.
        guard buttonsStackView.isHidden != tabItems[tabBar.selectedIndex].shouldHideButtonsView else {
            return
        }
        UIView.animate(withDuration: Appearance.tabBarAnimationsDuration) {
            let shouldHideButtons = tabItems[tabBar.selectedIndex].shouldHideButtonsView
            self.buttonsStackView.isHidden = shouldHideButtons
            self.horizontalDivider.isHidden = shouldHideButtons
        }
    }

    /// Filter button
    @objc private func didTapFilterButton() {
        //TODO: - READERNAV - Remove. This test code is for UI prototyping only
        guard filterButton.titleLabel?.text == "Filter" else {
            return
        }
        setFilterButtonTitle("Phoebe's Photos")
        resetFilterButton.isHidden = false
        viewModel.presentFilter()
    }

    /// Reset filter button
    @objc private func didTapResetFilterButton() {
        setFilterButtonTitle(Appearance.defaultFilterButtonTitle)
        resetFilterButton.isHidden = true
        viewModel.resetFilter()
    }

    @objc private func didTapSettingsButton() {
        viewModel.presentSettings()
    }
}


// MARK: - Appearance
extension ReaderTabView {

    private enum Appearance {
        static let barHeight: CGFloat = 48

        static let tabBarAnimationsDuration = 0.2

        static let defaultFilterButtonTitle = NSLocalizedString("Filter", comment: "Title of the filter button in the Reader")
        static let filterButtonMaxFontSize: CGFloat = 28.0
        static let filterButtonFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
        static let filterButtonInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        static let filterButtonimageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let filterButtonTitleInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)

        static let resetButtonWidth: CGFloat = 32
        static let resetButtonInsets = UIEdgeInsets(top: 1, left: -4, bottom: -1, right: 4)
        static let settingsButtonWidth: CGFloat = 56

        static let dividerWidth: CGFloat = .hairlineBorderWidth
        static let dividerColor: UIColor = .lightGray
        static let verticalDividerHeightMultiplier: CGFloat = 0.6
    }
}
