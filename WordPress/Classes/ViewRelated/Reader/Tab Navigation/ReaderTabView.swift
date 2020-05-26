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

        viewModel.didSelectIndex = { [weak self] index in
            self?.tabBar.setSelectedIndex(index)
            self?.toggleButtonsView()
        }

        viewModel.refreshTabBar { [weak self] tabItems, index in
            self?.tabBar.items = tabItems
            self?.tabBar.setSelectedIndex(index)
            self?.configureTabBarElements()
            self?.addContentToContainerView()
        }
        setupViewElements()
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
        setupVerticalDivider(verticalDivider)
        setupHorizontalDivider(horizontalDivider)
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
        viewModel.fetchReaderMenu()
    }

    private func configureTabBarElements() {
        guard let tabItem = tabBar.currentlySelectedItem as? ReaderTabItem else {
            return
        }
        buttonsStackView.isHidden = tabItem.shouldHideButtonsView
        horizontalDivider.isHidden = tabItem.shouldHideButtonsView
        settingsButton.isHidden = tabItem.shouldHideSettingsButton
        verticalDivider.isHidden = tabItem.shouldHideSettingsButton
    }

    private func setupButtonsView() {
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.isLayoutMarginsRelativeArrangement = true
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .fill
        buttonsStackView.addArrangedSubview(filterButton)
        buttonsStackView.addArrangedSubview(resetFilterButton)
        buttonsStackView.addArrangedSubview(verticalDivider)
        buttonsStackView.addArrangedSubview(settingsButton)
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

    private func setupVerticalDivider(_ divider: UIView) {
        divider.translatesAutoresizingMaskIntoConstraints = false
        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = Appearance.dividerColor
        divider.addSubview(dividerView)
        NSLayoutConstraint.activate([
            dividerView.centerYAnchor.constraint(equalTo: divider.centerYAnchor),
            dividerView.heightAnchor.constraint(equalTo: divider.heightAnchor, multiplier: Appearance.verticalDividerHeightMultiplier),
            dividerView.leadingAnchor.constraint(equalTo: divider.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: divider.trailingAnchor)
        ])
    }

    private func setupHorizontalDivider(_ divider: UIView) {
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = Appearance.dividerColor
    }

    private func setupSettingsButton() {
        settingsButton.accessibilityLabel = Appearance.settingsButtonAccessibilitylabel
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(didTapSettingsButton), for: .touchUpInside)
        WPStyleGuide.applyReaderSettingsButtonStyle(settingsButton)
        settingsButton.accessibilityIdentifier = Accessibility.settingsButtonIdentifier
        settingsButton.accessibilityLabel = Accessibility.settingsButtonLabel
        settingsButton.accessibilityHint = Accessibility.settingsButtonHint
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
    }

    private func activateConstraints() {
        pinSubviewToAllEdges(mainStackView)
        NSLayoutConstraint.activate([
            buttonsStackView.heightAnchor.constraint(equalToConstant: Appearance.barHeight),
            resetFilterButton.widthAnchor.constraint(equalToConstant: Appearance.resetButtonWidth),
            verticalDivider.widthAnchor.constraint(equalToConstant: Appearance.dividerWidth),
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
        viewModel.showTab(at: tabBar.selectedIndex)
        toggleButtonsView()
    }

    private func toggleButtonsView() {
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
    @objc private func didTapFilterButton() {
        /// Present from the image view to align to the left hand side
        viewModel.presentFilter(from: filterButton.imageView ?? filterButton) { [weak self] title in
            if let title = title {
                self?.resetFilterButton.isHidden = false
                self?.setFilterButtonTitle(title)
            }
        }
    }

    /// Reset filter button
    @objc private func didTapResetFilterButton() {
        setFilterButtonTitle(Appearance.defaultFilterButtonTitle)
        resetFilterButton.isHidden = true
        guard let tabItem = tabBar.currentlySelectedItem as? ReaderTabItem else {
            return
        }
        viewModel.resetFilter(selectedItem: tabItem)
    }

    @objc private func didTapSettingsButton() {
        viewModel.presentSettings(from: settingsButton)
    }
}

// MARK: - Appearance
extension ReaderTabView {

    private enum Appearance {
        static let barHeight: CGFloat = 48

        static let tabBarAnimationsDuration = 0.2

        static let settingsButtonAccessibilitylabel = NSLocalizedString("Manage", comment: "Label for managing sites and filters in the Reader tab")
        static let defaultFilterButtonTitle = NSLocalizedString("Filter", comment: "Title of the filter button in the Reader")
        static let filterButtonMaxFontSize: CGFloat = 28.0
        static let filterButtonFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .regular)
        static let filterButtonInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        static let filterButtonimageInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        static let filterButtonTitleInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)

        static let resetButtonWidth: CGFloat = 32
        static let resetButtonInsets = UIEdgeInsets(top: 1, left: -4, bottom: -1, right: 4)
        static let settingsButtonWidth: CGFloat = 56

        static let dividerWidth: CGFloat = .hairlineBorderWidth
        static let dividerColor: UIColor = .divider
        static let verticalDividerHeightMultiplier: CGFloat = 0.6
    }
}


// MARK: - Accessibility
extension ReaderTabView {
    private enum Accessibility {
        static let filterButtonIdentifier = "ReaderFilterButton"
        static let resetButtonIdentifier = "ReaderResetButton"
        static let resetFilterButtonLabel = NSLocalizedString("Reset filter", comment: "Accessibility label for the reset filter button in the reader.")
        static let settingsButtonIdentifier = "ReaderSettingsButton"
        static let settingsButtonLabel = NSLocalizedString("Manage", comment: "Accessibility label for the settings button in the reader.")
        static let settingsButtonHint = NSLocalizedString("Manage followed sites and tags", comment: "Accessibility hint for the settings button in the reader.")
    }
}
