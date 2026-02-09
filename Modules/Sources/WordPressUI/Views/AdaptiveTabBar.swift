import UIKit
import WordPressShared

public protocol AdaptiveTabBarItem: Identifiable {
    var localizedTitle: String { get }
}

public class AdaptiveTabBar: UIControl {

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollsToTop = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()

    private lazy var selectionIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .label
        view.layer.cornerRadius = 2
        view.isHidden = true
        return view
    }()

    // MARK: - Properties

    public var items: [any AdaptiveTabBarItem] = [] {
        didSet { refreshTabs() }
    }

    private var buttons: [TabButton] = []

    public private(set) var selectedIndex: Int = 0 {
        didSet {
            buttons[oldValue].isSelected = false
            buttons[selectedIndex].isSelected = true
        }
    }

    public var preferredFont = UIFont.preferredFont(forTextStyle: .body)

    private var widthConstraint: NSLayoutConstraint!
    private var indicatorWidthConstraint: NSLayoutConstraint?
    private var indicatorCenterXConstraint: NSLayoutConstraint?
    private var previousWidth: CGFloat?

    public static let tabBarHeight: CGFloat = 40

    // MARK: - Initialization

    public init() {
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(scrollView)
        scrollView.pinEdges()

        scrollView.addSubview(stackView)
        stackView.pinEdges()

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: AdaptiveTabBar.tabBarHeight),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        widthConstraint = stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)

        let separator = SeparatorView.horizontal(height: separatorHeight)
        addSubview(separator)
        separator.pinEdges([.horizontal, .bottom])

        addSubview(selectionIndicator)
        NSLayoutConstraint.activate([
            selectionIndicator.heightAnchor.constraint(equalToConstant: 2),
            selectionIndicator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Accessibility
        shouldGroupAccessibilityChildren = true
        accessibilityContainerType = .semanticGroup
    }

    private var separatorHeight: CGFloat {
        if #available(iOS 26, *) { 1 } else { 0.33 }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        if previousWidth != bounds.width {
            previousWidth = bounds.width
            updateDistribution()
        }
    }

    // MARK: - Tab Management

    private func refreshTabs() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = items.indices.map { createTab(at: $0) }
        buttons.forEach(stackView.addArrangedSubview)

        if !items.isEmpty {
            setSelectedIndex(0, animated: false)
        }

        setNeedsLayout()
    }

    private func createTab(at index: Int) -> TabButton {
        let item = items[index]
        let isFirstItem = index == 0
        let isLastItem = index == items.count - 1

        let button = TabButton()
        button.title = item.localizedTitle
        button.font = preferredFont
        button.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: isFirstItem ? 20 : 12,
            bottom: 8,
            trailing: isLastItem ? 20 : 12
        )
        button.accessibilityIdentifier = "\(item)"
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    @objc private func tabButtonTapped(_ sender: TabButton) {
        guard let index = buttons.firstIndex(of: sender) else { return }
        setSelectedIndex(index)
        sendActions(for: .valueChanged)
    }

    private func updateDistribution() {
        guard !buttons.isEmpty else { return }

        let availableWidth = safeAreaLayoutGuide.layoutFrame.width

        // Calculate preferred width for each button
        let preferredWidths = buttons.map {
            $0.systemLayoutSizeFitting(CGSize(width: UIView.noIntrinsicMetric, height: AdaptiveTabBar.tabBarHeight)).width
        }

        let maxWidth = preferredWidths.max() ?? 0
        let totalWidth = preferredWidths.reduce(0, +)

        // Adding 2 for potential rounding errors
        if (maxWidth * CGFloat(buttons.count) + 2) <= availableWidth {
            // Use fill equally - all buttons same width
            stackView.distribution = .fillEqually
            widthConstraint.isActive = true
            scrollView.isScrollEnabled = false
        } else if (totalWidth + 2) <= availableWidth {
            // Use fill proportionally - buttons sized by content
            stackView.distribution = .fillProportionally
            widthConstraint.isActive = true
            scrollView.isScrollEnabled = false
        } else {
            // Enable scrolling
            stackView.distribution = .fillProportionally
            widthConstraint.isActive = false
            scrollView.isScrollEnabled = true
        }
    }

    // MARK: - Selection

    public func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard items.indices.contains(index) else { return }

        UIView.performWithoutAnimation {
            selectedIndex = index
            layoutIfNeeded() // Update buttons without animation
        }

        updateSelectionIndicator(animated: animated)
        scrollToSelectedTab(animated: animated)
    }

    private func updateSelectionIndicator(animated: Bool) {
        guard selectedIndex < buttons.count else { return }

        let selectedTab = buttons[selectedIndex]

        indicatorCenterXConstraint?.isActive = false
        indicatorWidthConstraint?.isActive = false

        indicatorCenterXConstraint = selectionIndicator.centerXAnchor.constraint(equalTo: selectedTab.centerXAnchor)
        indicatorWidthConstraint = selectionIndicator.widthAnchor.constraint(equalTo: selectedTab.widthAnchor)

        indicatorCenterXConstraint?.isActive = true
        indicatorWidthConstraint?.isActive = true

        if selectionIndicator.isHidden || !animated {
            selectionIndicator.isHidden = false
            layoutIfNeeded()
        } else {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: -0.5,
                options: .curveEaseInOut
            ) {
                self.layoutIfNeeded()
            }
        }
    }

    private func scrollToSelectedTab(animated: Bool) {
        guard scrollView.isScrollEnabled,
              selectedIndex < buttons.count,
              scrollView.contentSize.width > scrollView.frame.width else {
            return
        }

        let selectedTab = buttons[selectedIndex]
        let tabFrame = scrollView.convert(selectedTab.frame, from: stackView)
        let visibleRect = scrollView.bounds

        // Only scroll if the button is not fully visible
        guard !visibleRect.contains(tabFrame) else {
            return
        }

        let targetRect = CGRect(
            x: max(0, tabFrame.midX - bounds.width / 2),
            y: 0,
            width: bounds.width,
            height: bounds.height
        )

        scrollView.scrollRectToVisible(targetRect, animated: animated)
    }

    var currentlySelectedItem: (any AdaptiveTabBarItem)? {
        return items[safe: selectedIndex]
    }
}

// MARK: - TabButton

private class TabButton: UIControl {
    private let label = UILabel()

    var title: String = "" {
        didSet {
            label.text = title
            accessibilityLabel = title
            invalidateIntrinsicContentSize()
        }
    }

    var font: UIFont = .preferredFont(forTextStyle: .body) {
        didSet {
            updateAppearance()
            invalidateIntrinsicContentSize()
        }
    }

    var contentInsets: NSDirectionalEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateAppearance()
            updateAccessibility()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(label)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        label.maximumContentSizeCategory = .extraLarge
        label.isAccessibilityElement = false

        isAccessibilityElement = true
        accessibilityTraits = .button

        updateAppearance()
        updateAccessibility()
    }

    private func updateAppearance() {
        label.font = font.withWeight(isSelected ? .medium : .regular)
        label.textColor = isSelected ? .label : .secondaryLabel
    }

    private func updateAccessibility() {
        if isSelected {
            accessibilityTraits = [.button, .selected]
        } else {
            accessibilityTraits = .button
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.inset(by: UIEdgeInsets(
            top: contentInsets.top,
            left: contentInsets.leading,
            bottom: contentInsets.bottom,
            right: contentInsets.trailing
        ))
    }

    override var intrinsicContentSize: CGSize {
        // Always calculate based on medium weight (selected state)
        let mediumFont = font.withWeight(.medium)
        let size = title.size(withAttributes: [.font: mediumFont])

        // Add small padding to prevent clipping due to rounding
        return CGSize(
            width: ceil(size.width) + contentInsets.leading + contentInsets.trailing + 2,
            height: ceil(size.height) + contentInsets.top + contentInsets.bottom
        )
    }
}

// MARK: - Preview

#if DEBUG
import SwiftUI

private struct PreviewTabItem: AdaptiveTabBarItem {
    let id: String
    let localizedTitle: String
}

private class AdaptiveTabBarPreviewViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 40
        view.addSubview(stackView)
        stackView.pinEdges([.top, .leading, .trailing], to: view.safeAreaLayoutGuide, insets: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))

        // Auto: Fill mode (fits with equal distribution)
        let autoFill = createSection(
            title: "Auto: Fill Mode (Equal Width)",
            items: [
                PreviewTabItem(id: "1", localizedTitle: "Tab 1"),
                PreviewTabItem(id: "2", localizedTitle: "Tab 2"),
                PreviewTabItem(id: "3", localizedTitle: "Tab 3")
            ]
        )
        stackView.addArrangedSubview(autoFill)

        // Auto: Proportional mode (fill doesn't fit, but proportional does)
        let autoProportional = createSection(
            title: "Auto: Proportional Mode (Varying Widths)",
            items: [
                PreviewTabItem(id: "1", localizedTitle: "Traffic"),
                PreviewTabItem(id: "2", localizedTitle: "Insights"),
                PreviewTabItem(id: "3", localizedTitle: "Subscribers"),
                PreviewTabItem(id: "4", localizedTitle: "Ads")
            ]
        )
        stackView.addArrangedSubview(autoProportional)

        // Auto: Scrollable (neither fits)
        let autoScrollable = createSection(
            title: "Auto: Scrollable (Overflows)",
            items: [
                PreviewTabItem(id: "1", localizedTitle: "Traffic"),
                PreviewTabItem(id: "2", localizedTitle: "Insights"),
                PreviewTabItem(id: "3", localizedTitle: "Subscribers"),
                PreviewTabItem(id: "4", localizedTitle: "Ads"),
                PreviewTabItem(id: "5", localizedTitle: "Performance"),
                PreviewTabItem(id: "6", localizedTitle: "Blaze"),
            ]
        )
        stackView.addArrangedSubview(autoScrollable)
    }

    private func createSection(title: String, items: [PreviewTabItem]) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        container.addArrangedSubview(label)

        let tabBar = AdaptiveTabBar()
        tabBar.items = items
        container.addArrangedSubview(tabBar)

        return container
    }
}

#Preview("AdaptiveTabBar Configurations") {
    AdaptiveTabBarPreviewViewController()
}
#endif
