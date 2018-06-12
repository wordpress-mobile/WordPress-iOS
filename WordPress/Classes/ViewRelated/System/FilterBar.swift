import UIKit

/// Filter Tab Bar is a tabbed control (much like a segmented control), but
/// has an appearance similar to Android tabs.
///
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

    /// Titles of tabs to display.
    ///
    @IBInspectable var items: [String] = [] {
        didSet {
            refreshTabs()
        }
    }

    // MARK: - Appearance

    /// Tint color will be applied to titles of selected tabs, and the floating
    /// selection indicator.
    ///
    override var tintColor: UIColor! {
        didSet {
            tabs.forEach({
                $0.tintColor = tintColor
                $0.setTitleColor(tintColor, for: .selected)
                $0.setTitleColor(tintColor, for: .highlighted)
            })
            selectionIndicator.backgroundColor = tintColor
        }
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

    init(items: [String]) {
        self.items = items

        super.init(frame: .zero)

        refreshTabs()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        heightAnchor.constraint(equalToConstant: AppearanceMetrics.height).isActive = true

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
        tabs = items.map(makeTab(_:))
        tabs.forEach(stackView.addArrangedSubview(_:))

        layoutIfNeeded()

        setSelectedIndex(selectedIndex, animated: false)
    }

    private func makeTab(_ title: String) -> UIButton {
        let tab = TabBarButton(type: .custom)
        tab.setTitle(title, for: .normal)
        tab.setTitleColor(tintColor, for: .selected)
        tab.setTitleColor(deselectedTabColor, for: .normal)
        tab.tintColor = tintColor

        tab.contentEdgeInsets = AppearanceMetrics.buttonInsets
        tab.sizeToFit()

        tab.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        return tab
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
            stackView.distribution = .fillEqually
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
            }, completion: nil)
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

        let leadingConstant = (tabSizingStyle == .equalWidths) ? 0.0 : tab.contentEdgeInsets.left
        let trailingConstant = (tabSizingStyle == .equalWidths) ? 0.0 : -tab.contentEdgeInsets.right

        selectionIndicatorLeadingConstraint = selectionIndicator.leadingAnchor.constraint(equalTo: tab.leadingAnchor, constant: leadingConstant)
        selectionIndicatorTrailingConstraint = selectionIndicator.trailingAnchor.constraint(equalTo: tab.trailingAnchor, constant: trailingConstant)

        selectionIndicatorLeadingConstraint?.isActive = true
        selectionIndicatorTrailingConstraint?.isActive = true
    }

    private enum AppearanceMetrics {
        static let height: CGFloat = 46.0
        static let bottomDividerHeight: CGFloat = 1.0
        static let selectionIndicatorHeight: CGFloat = 2.0
        static let horizontalPadding: CGFloat = 4.0
        static let buttonInsets = UIEdgeInsets(top: 14.0, left: 12.0, bottom: 14.0, right: 12.0)
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            titleLabel?.font = WPStyleGuide.fontForTextStyle(.footnote, maximumPointSize: TabFont.maxSize)
        }
    }
}

extension FilterTabBar: Accessible {
    func prepareForVoiceOver() {
        isAccessibilityElement = false
        accessibilityTraits = super.accessibilityTraits | UIAccessibilityTraitTabBar
    }
}
