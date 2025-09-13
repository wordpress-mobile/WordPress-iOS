import UIKit

@MainActor
public final class AdaptiveTabBarController<Item: AdaptiveTabBarItem> {
    private(set) public var items: [Item] = []

    public var selection: Item? {
        didSet {
            guard oldValue?.id != selection?.id else { return }
            if let index = selectionIndex {
                if filterBar.selectedIndex != index {
                    filterBar.setSelectedIndex(index)
                }
                if segmentedControl.selectedSegmentIndex != index, segmentedControl.numberOfSegments >= index {
                    segmentedControl.selectedSegmentIndex = index
                }
            }
        }
    }

    public var selectionIndex: Int? {
        items.firstIndex(where: { $0.id == selection?.id })
    }

    public var accessibilityIdentifier: String? {
        didSet {
            filterBar.accessibilityIdentifier = accessibilityIdentifier
            segmentedControl.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    public let filterBar = AdaptiveTabBar()
    private var filterBarContainer = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

    public let segmentedControl = UISegmentedControl()

    private weak var viewController: UIViewController?

    private var onSelectionChanged: ((Item) -> Void)?

    private var isFilterBarHidden = false
    private var lastContentOffset: CGFloat = 0
    private var scrollViewObserver: NSKeyValueObservation?
    private var traitObserver: NSObjectProtocol?

    public var navigationItem: UINavigationItem?

    public init() {
        setupFilterBar()
        setupSegmentedControl()
    }

    private func setupFilterBar() {
//        filterBarContainer.backgroundColor = .systemGroupedBackground // .secondarySystemGroupedBackground
        filterBarContainer.contentView.addSubview(filterBar)
        filterBar.pinEdges(.top, to: filterBarContainer.safeAreaLayoutGuide, insets: UIEdgeInsets(.top, -filterBar.tabBarHeight))
        filterBar.pinEdges([.horizontal, .bottom])

        filterBar.addTarget(self, action: #selector(selectedFilterDidChange), for: .valueChanged)
    }

    private func setupSegmentedControl() {
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
    }

    public func configure(_ items: [Item], in viewController: UIViewController, onSelectionChanged: @escaping (Item) -> Void) {
        self.items = items
        self.selection = items.first
        self.viewController = viewController
        self.onSelectionChanged = onSelectionChanged

        filterBar.items = items

        segmentedControl.removeAllSegments()
        for (index, item) in items.enumerated() {
            segmentedControl.insertSegment(withTitle: item.localizedTitle, at: index, animated: false)
        }
        segmentedControl.selectedSegmentIndex = 0

        setupTraitObserver(for: viewController)
        refresh()
    }

    private func refresh() {
        guard let viewController else { return }

        if viewController.traitCollection.horizontalSizeClass == .regular {
            filterBarContainer.removeFromSuperview()
            (navigationItem ?? viewController.navigationItem).leftBarButtonItem = UIBarButtonItem(customView: segmentedControl)
            viewController.additionalSafeAreaInsets = .zero
        } else {
            viewController.navigationItem.titleView = nil
            viewController.view.addSubview(filterBarContainer)
            filterBarContainer.pinEdges([.top, .horizontal])
            viewController.additionalSafeAreaInsets = UIEdgeInsets(.top, filterBar.tabBarHeight)
        }
    }

    private func setupTraitObserver(for viewController: UIViewController) {
        if #available(iOS 17, *) {
            traitObserver = viewController.registerForTraitChanges([UITraitHorizontalSizeClass.self]) { [weak self] (viewController: UIViewController, previousTraitCollection: UITraitCollection) in
                self?.refresh()
            }
        }
    }

    // MARK: - Auto Hiding

    public func enableAutomaticHiding(in scrollView: UIScrollView) {
        guard #available(iOS 26, *) else { return }

        lastContentOffset = scrollView.contentOffset.y
        scrollViewObserver = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            MainActor.assumeIsolated {
                self?.scrollViewDidChangeContentOffset(scrollView)
            }
        }
    }

    private func scrollViewDidChangeContentOffset(_ scrollView: UIScrollView) {
        guard filterBarContainer.superview != nil else { return }

        let currentOffset = scrollView.contentOffset.y
        let offsetDelta = abs(currentOffset - lastContentOffset)

        // Only react to significant scroll movements to avoid jitter
        guard offsetDelta > 2 else { return }

        // Calculate the maximum valid content offset (bottom of content)
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.bounds.height
        let contentInsets = scrollView.adjustedContentInset
        let maxContentOffset = max(0, contentHeight + contentInsets.bottom - scrollViewHeight)

        // Ignore bounce effects - only react to scrolling within content bounds
        let isAtBottomBounce = currentOffset > maxContentOffset
        let wasAtBottomBounce = lastContentOffset > maxContentOffset

        if currentOffset > lastContentOffset && currentOffset > 0 && !isAtBottomBounce {
            // Scrolling down within content - hide immediately
            setFilterBarHidden(true, animated: true)
        } else if currentOffset < lastContentOffset && !isAtBottomBounce && !wasAtBottomBounce {
            // Scrolling up within content - show immediately
            setFilterBarHidden(false, animated: true)
        }
        lastContentOffset = currentOffset
    }

    private func setFilterBarHidden(_ isHidden: Bool, animated: Bool) {
        guard isFilterBarHidden != isHidden else { return }
        self.isFilterBarHidden = isHidden

        // Only animate filter bar, not segmented control in navigation bar
        guard viewController?.traitCollection.horizontalSizeClass != .regular else { return }

        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut]) {
            self.filterBarContainer.transform = isHidden ? CGAffineTransform(translationX: 0, y: -44) : .identity
            self.filterBarContainer.alpha = isHidden ? 0 : 1
        }
    }

    // MARK: - Actions

    @objc private func selectedFilterDidChange(_ filterBar: AdaptiveTabBar) {
        let item = items[filterBar.selectedIndex]
        self.selection = item
        onSelectionChanged?(item)
    }

    @objc private func segmentedControlValueChanged(_ segmentedControl: UISegmentedControl) {
        let item = items[segmentedControl.selectedSegmentIndex]
        self.selection = item
        onSelectionChanged?(item)
    }
}
