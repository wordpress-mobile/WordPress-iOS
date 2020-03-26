import UIKit

class ReaderTabView: UIView {

    private var mainStackView: UIStackView
    private var tabBar: FilterTabBar
    private var filterButton: PostMetaButton
    private var resetFilterButton: UIButton
    private var verticalDivider: UIView
    private var settingsButton: UIButton
    private var buttonsStackView: UIStackView
    private var containerView: UIView

    init() {
        func makeTabBar() -> FilterTabBar {
            let tabBar = FilterTabBar()
            let sections: [ReaderSection] = [.following, .discover, .likes, .saved]
            tabBar.items = sections
            return tabBar
        }
        tabBar = makeTabBar()

        mainStackView = UIStackView()
        buttonsStackView = UIStackView()
        filterButton = PostMetaButton(type: .custom)
        resetFilterButton = UIButton(type: .custom)
        verticalDivider = UIView()
        settingsButton = UIButton(type: .custom)
        containerView = UIView()

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
        setupVerticalDivider()
        setupSettingsButton()
        setupContainerView()
        activateConstraints()
    }

    private func setupMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        addSubview(mainStackView)
        mainStackView.addArrangedSubview(tabBar)
        mainStackView.addArrangedSubview(buttonsStackView)
        mainStackView.addArrangedSubview(containerView)
    }

    private func setupTabBar() {
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.tabBarHeight = Appearance.barHeight
        WPStyleGuide.configureFilterTabBar(tabBar)
        tabBar.addTarget(self, action: #selector(selectedTabDidChange(_:)), for: .valueChanged)
    }

    private func setupButtonsView() {
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
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

    private func setupVerticalDivider() {
        verticalDivider.translatesAutoresizingMaskIntoConstraints = false
        verticalDivider.backgroundColor = .divider
    }

    private func setupSettingsButton() {
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        WPStyleGuide.applyReaderSettingsButtonStyle(settingsButton)
    }

    private func setupContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .lightGray
    }

    private func activateConstraints() {
        pinSubviewToSafeArea(mainStackView)
        NSLayoutConstraint.activate([
            buttonsStackView.heightAnchor.constraint(equalToConstant: Appearance.barHeight),
            resetFilterButton.widthAnchor.constraint(equalToConstant: Appearance.resetButtonWidth),
            verticalDivider.widthAnchor.constraint(equalToConstant: Appearance.verticalDividerWidth),
            verticalDivider.heightAnchor.constraint(equalTo: buttonsStackView.heightAnchor,
                                                    multiplier: Appearance.verticalDividerHeightMultiplier),
            settingsButton.widthAnchor.constraint(equalToConstant: Appearance.settingsButtonWidth)
        ])
    }
}

// MARK: - Actions
extension ReaderTabView {
    /// Tab bar
    @objc private func selectedTabDidChange(_ tabBar: FilterTabBar) {
        // hide/show buttons view depending on the selected TabBarItem
        guard let tabItems = tabBar.items as? [ReaderSection],
            buttonsStackView.isHidden != tabItems[tabBar.selectedIndex].shouldHideButtonsView else {
            return
        }
        UIView.animate(withDuration: Appearance.animationDuration) {
            self.buttonsStackView.isHidden = tabItems[tabBar.selectedIndex].shouldHideButtonsView
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
    }
    /// Reset filter button
    @objc private func didTapResetFilterButton() {
        setFilterButtonTitle(Appearance.defaultFilterButtonTitle)
        resetFilterButton.isHidden = true
    }
}


// MARK: - Appearance
extension ReaderTabView {

    private enum Appearance {
        static let barHeight: CGFloat = 48

        static let animationDuration = 0.2

        static let defaultFilterButtonTitle = NSLocalizedString("Filter", comment: "Title of the filter button in the Reader")
        static let filterButtonMaxFontSize: CGFloat = 28.0
        static let filterButtonFont = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
        static let filterButtonInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        static let filterButtonimageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let filterButtonTitleInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)


        static let resetButtonWidth: CGFloat = 32
        static let resetButtonInsets = UIEdgeInsets(top: 1, left: -4, bottom: -1, right: 4)
        static let settingsButtonWidth: CGFloat = 56

        static let verticalDividerWidth: CGFloat = 1
        static let verticalDividerHeightMultiplier: CGFloat = 0.6
    }
}
