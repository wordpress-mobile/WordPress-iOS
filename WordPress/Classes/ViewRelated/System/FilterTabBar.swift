import UIKit

/// Filter Tab Bar is a tabbed control (much like a segmented control), but
/// has an appearance similar to Android tabs.
///

protocol FilterTabBarItem {
    var title: String { get }
    var attributedTitle: NSAttributedString? { get }
    var accessibilityIdentifier: String { get }
}

extension FilterTabBarItem {
    var attributedTitle: NSAttributedString? { return nil }
}

extension FilterTabBarItem where Self: RawRepresentable {

    var accessibilityIdentifier: String {
        return "\(self)"
    }
}

class FilterTabBar: UIControl {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 0
        return stackView
    }()

    private let selectionIndicator: UIView = {
        let selectionIndicator = UIView()
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.isHidden = true

        return selectionIndicator
    }()

    private let divider: UIView = {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false

        return divider
    }()

    var items: [FilterTabBarItem] = [] {
        didSet {
            refreshTabs()
        }
    }

    private var tabBarHeightConstraint: NSLayoutConstraint! {
        didSet {
            if let oldValue = oldValue {
                NSLayoutConstraint.deactivate([oldValue])
            }
        }
    }

    var tabBarHeight = AppearanceMetrics.height {
        didSet {
            tabBarHeightConstraint = heightAnchor.constraint(equalToConstant: tabBarHeight)
        }
    }

    var equalWidthFill: UIStackView.Distribution = .fillEqually {
        didSet {
            stackView.distribution = equalWidthFill
        }
    }

    var equalWidthSpacing: CGFloat = 0 {
        didSet {
            stackView.spacing = equalWidthSpacing
        }
    }

    // MARK: - Appearance

    /// Tint color will be applied to the floating selection indicator.
    /// If selectedTitleColor is not provided, tint color will also be applied to
    /// titles of selected tabs.
    ///
    override var tintColor: UIColor! {
        didSet {
            tabs.forEach({
                $0.tintColor = tintColor
                $0.setTitleColor(titleColorForSelected, for: .selected)
                $0.setTitleColor(titleColorForSelected, for: .highlighted)

                $0.setAttributedTitle(addColor(titleColorForSelected, toAttributedString: $0.currentAttributedTitle),
                                      for: .selected)
                $0.setAttributedTitle(addColor(titleColorForSelected, toAttributedString: $0.currentAttributedTitle),
                                      for: .highlighted)
            })
            selectionIndicator.backgroundColor = tintColor
        }
    }

    /// Selected Title Color will be applied to titles of selected tabs.
    ///
    var selectedTitleColor: UIColor? {
        didSet {
            tabs.forEach({
                $0.setTitleColor(selectedTitleColor, for: .selected)
                $0.setTitleColor(selectedTitleColor, for: .highlighted)
            })
        }
    }

    private var titleColorForSelected: UIColor {
        return selectedTitleColor ?? tintColor
    }

    var deselectedTabColor: UIColor = .lightGray {
        didSet {
            tabs.forEach({ $0.setTitleColor(deselectedTabColor, for: .normal) })
        }
    }

    var dividerColor: UIColor = .lightGray {
        didSet {
            divider.backgroundColor = dividerColor
        }
    }

    /// Accessory view displayed on the leading end of the tab bar.
    ///
    var accessoryView: UIView? = nil {
        didSet {
            if let oldValue = oldValue {
                oldValue.removeFromSuperview()
            }

            if let accessoryView = accessoryView {
                accessoryView.setContentCompressionResistancePriority(.required, for: .horizontal)
                stackView.insertArrangedSubview(accessoryView, at: 0)
            }
        }
    }

    // MARK: - Tab Sizing

    private var stackViewEdgeConstraints: [NSLayoutConstraint]! {
        didSet {
            if let oldValue = oldValue {
                NSLayoutConstraint.deactivate(oldValue)
            }
        }
    }

    private var stackViewWidthConstraint: NSLayoutConstraint! {
        didSet {
            if let oldValue = oldValue {
                NSLayoutConstraint.deactivate([oldValue])
            }
        }
    }

    enum TabSizingStyle {
        /// The tabs will fill the space available to the filter bar,
        /// with all tabs having equal widths. Tabs will not scroll.
        /// Because of different language widths, ideally this should only be
        /// used for 3 tabs or less.
        case equalWidths
        /// The tabs will have differing widths which fit their content size.
        /// If the tabs are too large to fit in the area available, the
        /// filter bar will scroll.
        case fitting
    }

    /// Defines how the tabs should be sized within the tab view.
    ///
    var tabSizingStyle: TabSizingStyle = .fitting {
        didSet {
            updateTabSizingConstraints()
            activateTabSizingConstraints()
        }
    }

    // MARK: - Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        tabBarHeightConstraint = heightAnchor.constraint(equalToConstant: tabBarHeight)
        tabBarHeightConstraint?.isActive = true

        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AppearanceMetrics.bottomDividerHeight),
            scrollView.topAnchor.constraint(equalTo: topAnchor)
            ])

        scrollView.addSubview(stackView)

        stackViewWidthConstraint = stackView.widthAnchor.constraint(equalTo: widthAnchor)

        updateTabSizingConstraints()
        activateTabSizingConstraints()

        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AppearanceMetrics.bottomDividerHeight),
            stackView.topAnchor.constraint(equalTo: topAnchor)
            ])

        addSubview(selectionIndicator)
        NSLayoutConstraint.activate([
            selectionIndicator.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: AppearanceMetrics.selectionIndicatorHeight)
        ])

        divider.backgroundColor = dividerColor
        addSubview(divider)
        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: AppearanceMetrics.bottomDividerHeight)
            ])
    }

    // MARK: - Tabs

    private var tabs: [UIButton] = []

    private func refreshTabs() {
        tabs.forEach({ $0.removeFromSuperview() })
        tabs = items.map(makeTab)
        stackView.addArrangedSubviews(tabs)

        layoutIfNeeded()

        setSelectedIndex(selectedIndex, animated: false)
    }

    private func makeTab(_ item: FilterTabBarItem) -> UIButton {

        let tab = TabBarButton(type: .custom)
        tab.setTitle(item.title, for: .normal)
        tab.setTitleColor(titleColorForSelected, for: .selected)
        tab.setTitleColor(deselectedTabColor, for: .normal)
        tab.tintColor = tintColor

        tab.setAttributedTitle(item.attributedTitle, for: .normal)
        tab.titleLabel?.lineBreakMode = .byWordWrapping
        tab.titleLabel?.textAlignment = .center
        tab.setAttributedTitle(addColor(titleColorForSelected, toAttributedString: item.attributedTitle), for: .selected)
        tab.setAttributedTitle(addColor(deselectedTabColor, toAttributedString: item.attributedTitle), for: .normal)

        tab.accessibilityIdentifier = item.accessibilityIdentifier

        tab.contentEdgeInsets = item.attributedTitle != nil ?
            AppearanceMetrics.buttonInsetsAttributedTitle :
            AppearanceMetrics.buttonInsets

        tab.sizeToFit()

        tab.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        return tab
    }

    private func addColor(_ color: UIColor, toAttributedString attributedString: NSAttributedString?) -> NSAttributedString? {

        guard let attributedString = attributedString else {
            return nil
        }

        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        mutableString.addAttributes([.foregroundColor: color], range: NSMakeRange(0, mutableString.string.count))

        return mutableString
    }

    private func updateTabSizingConstraints() {
        let padding = (tabSizingStyle == .equalWidths) ? 0 : AppearanceMetrics.horizontalPadding

        stackViewEdgeConstraints = [
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -padding)
        ]
    }

    private func activateTabSizingConstraints() {
        NSLayoutConstraint.activate(stackViewEdgeConstraints)

        switch tabSizingStyle {
        case .equalWidths:
            stackView.distribution = equalWidthFill
            stackView.spacing = equalWidthSpacing
            NSLayoutConstraint.activate([stackViewWidthConstraint])
        case .fitting:
            stackView.distribution = .fill
            NSLayoutConstraint.deactivate([stackViewWidthConstraint])
        }
    }

    // MARK: - Tab Selection

    @objc
    private func tabTapped(_ tab: UIButton) {
        guard let index = tabs.index(of: tab) else {
            return
        }

        setSelectedIndex(index)
        sendActions(for: .valueChanged)
    }

    /// The index of the currently selected tab.
    ///
    private(set) var selectedIndex: Int = 0 {
        didSet {
            if selectedIndex != oldValue && oldValue < tabs.count {
                let oldTab = tabs[oldValue]
                oldTab.isSelected = false
            }
        }
    }

    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        selectedIndex = index

        guard let tab = selectedTab else {
            return
        }

        tab.isSelected = true
        moveSelectionIndicator(to: selectedIndex, animated: animated)
        scroll(to: tab, animated: animated)
    }

    private var selectedTab: UIButton? {
        guard selectedIndex < tabs.count else {
            return nil
        }

        return tabs[selectedIndex]
    }

    // Used to adjust the position of the selection indicator to track the
    // currently selected tab.
    private var selectionIndicatorLeadingConstraint: NSLayoutConstraint? = nil
    private var selectionIndicatorTrailingConstraint: NSLayoutConstraint? = nil

    private func moveSelectionIndicator(to index: Int, animated: Bool = true) {
        guard index < tabs.count else {
            return
        }

        let tab = tabs[index]

        updateSelectionIndicatorConstraints(for: tab)

        if selectionIndicator.isHidden || animated == false {
            selectionIndicator.isHidden = false
            selectionIndicator.layoutIfNeeded()
        } else {
            UIView.animate(withDuration: SelectionAnimation.duration,
                           delay: 0,
                           usingSpringWithDamping: SelectionAnimation.springDamping,
                           initialSpringVelocity: SelectionAnimation.initialVelocity,
                           options: .curveEaseInOut,
                           animations: {
                self.layoutIfNeeded()
            })
        }
    }

    /// Intelligently scrolls the tab bar to the specified tab.
    ///
    /// * If the tab's center is within half the bar's width from the leading
    ///   edge of the bar, the bar will scroll all the way to the beginning.
    /// * If the tab's center is within half the bar's width from the trailing
    ///   edge of the bar, the bar will scroll all the way to the end.
    /// * Otherwise, the bar will scroll so that the specified tab is centered.
    ///
    private func scroll(to tab: UIButton, animated: Bool = true) {
        // Check the bar has enough content to scroll
        guard scrollView.contentSize.width > scrollView.frame.width else {
            return
        }

        let tabCenterX = scrollView.convert(tab.frame, from: stackView).midX

        if tabCenterX <= bounds.midX {
            // If the tab is within the first half width of the bar, scroll to the beginning
            scrollView.setContentOffset(.zero, animated: animated)
        } else if tabCenterX > scrollView.contentSize.width - bounds.midX {
            // If the tab is within the last half width of the bar, scroll to the end
            scrollView.setContentOffset(CGPoint(x: scrollView.contentSize.width - bounds.width, y: 0), animated: animated)
        } else {
            // Otherwise scroll so the tab is centered
            let centerPoint = CGPoint(x: tabCenterX - bounds.midX, y: 0)
            scrollView.setContentOffset(centerPoint, animated: animated)
        }
    }

    /// Move the selection indicator to below the specified tab.
    ///
    private func updateSelectionIndicatorConstraints(for tab: UIButton) {
        selectionIndicatorLeadingConstraint?.isActive = false
        selectionIndicatorTrailingConstraint?.isActive = false

        let buttonInsets = tab.currentAttributedTitle != nil ?
            AppearanceMetrics.buttonInsetsAttributedTitle :
            AppearanceMetrics.buttonInsets

        let leadingConstant = (tabSizingStyle == .equalWidths) ? 0.0 : (tab.contentEdgeInsets.left - buttonInsets.left)
        let trailingConstant = (tabSizingStyle == .equalWidths) ? 0.0 : (-tab.contentEdgeInsets.right + buttonInsets.right)

        selectionIndicatorLeadingConstraint = selectionIndicator.leadingAnchor.constraint(equalTo: tab.leadingAnchor, constant: leadingConstant)
        selectionIndicatorTrailingConstraint = selectionIndicator.trailingAnchor.constraint(equalTo: tab.trailingAnchor, constant: trailingConstant)

        selectionIndicatorLeadingConstraint?.isActive = true
        selectionIndicatorTrailingConstraint?.isActive = true
    }

    private enum AppearanceMetrics {
        static let height: CGFloat = 46.0
        static let bottomDividerHeight: CGFloat = 0.5
        static let selectionIndicatorHeight: CGFloat = 2.0
        static let horizontalPadding: CGFloat = 0.0
        static let buttonInsets = UIEdgeInsets(top: 14.0, left: 12.0, bottom: 14.0, right: 12.0)
        static let buttonInsetsAttributedTitle = UIEdgeInsets(top: 10.0, left: 2.0, bottom: 10.0, right: 2.0)
    }

    private enum SelectionAnimation {
        static let duration: TimeInterval = 0.3
        static let springDamping: CGFloat = 0.9
        static let initialVelocity: CGFloat = -0.5
    }
}

private class TabBarButton: UIButton {
    private enum TabFont {
        static let maxSize: CGFloat = 28.0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setFont()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setFont()
    }

    private func setFont() {
        titleLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, symbolicTraits: .traitBold, maximumPointSize: TabFont.maxSize)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            setFont()
        }
    }
}

extension FilterTabBar: Accessible {
    func prepareForVoiceOver() {
        isAccessibilityElement = false
        accessibilityTraits = [super.accessibilityTraits, .tabBar]
    }
}
