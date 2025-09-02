import UIKit
import WordPressShared

public protocol AdaptiveTabBarItem {
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

    var items: [AdaptiveTabBarItem] = [] {
        didSet { refreshTabs() }
    }

    private var buttons: [UIButton] = []

    private(set) var selectedIndex: Int = 0 {
        didSet {
            buttons[oldValue].isSelected = false
            buttons[selectedIndex].isSelected = true
        }
    }

    private var widthConstraint: NSLayoutConstraint!
    private var indicatorWidthConstraint: NSLayoutConstraint?
    private var indicatorCenterXConstraint: NSLayoutConstraint?

    public let tabBarHeight: CGFloat = 44

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
            heightAnchor.constraint(equalToConstant: tabBarHeight),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        widthConstraint = stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)

        let separator = SeparatorView.horizontal()
        addSubview(separator)
        separator.pinEdges([.horizontal, .bottom])

        addSubview(selectionIndicator)
        NSLayoutConstraint.activate([
            selectionIndicator.heightAnchor.constraint(equalToConstant: 2),
            selectionIndicator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateDistribution()
    }

    // MARK: - Tab Management

    private func refreshTabs() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = items.indices.map(createTab)
        buttons.forEach(stackView.addArrangedSubview)

        if !items.isEmpty {
            setSelectedIndex(0, animated: false)
        }

        setNeedsLayout()
    }

    private func createTab(at index: Int) -> UIButton {
        let item = items[index]

        var config = UIButton.Configuration.plain()
        config.title = item.localizedTitle
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)

        let button = UIButton(configuration: config, primaryAction: .init { [weak self] _ in
            self?.tabButtonTapped(at: index)
        })

        button.configurationUpdateHandler = { button in
            let isSelected = button.state.contains(.selected)

            var config = button.configuration ?? .plain()
            config.baseBackgroundColor = .clear
            config.baseForegroundColor = isSelected ? .label : .secondaryLabel
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.preferredFont(forTextStyle: .headline)
                    .withWeight(isSelected ? .medium : .regular)
                return outgoing
            }
            button.configuration = config
        }

        button.accessibilityIdentifier = "\(item)"
        button.maximumContentSizeCategory = .extraLarge

        return button
    }

    private func updateDistribution() {
        guard !buttons.isEmpty else { return }

        let totalPreferredWidth = buttons.reduce(0) { total, tab in
            total + tab.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: tabBarHeight)).width
        }

        // If the items don't fit, enable scrolling
        let shouldFillWidth = totalPreferredWidth <= bounds.width
        if shouldFillWidth {
            stackView.distribution = .fillEqually
            widthConstraint.isActive = true
            scrollView.isScrollEnabled = false
        } else {
            stackView.distribution = .fill
            widthConstraint.isActive = false
            scrollView.isScrollEnabled = true
        }
    }

    // MARK: - Selection

    private func tabButtonTapped(at index: Int) {
        setSelectedIndex(index)
        sendActions(for: .valueChanged)
    }

    func setSelectedIndex(_ index: Int, animated: Bool = true) {
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
        let targetRect = CGRect(
            x: max(0, tabFrame.midX - bounds.width / 2),
            y: 0,
            width: bounds.width,
            height: bounds.height
        )

        scrollView.scrollRectToVisible(targetRect, animated: animated)
    }

    var currentlySelectedItem: AdaptiveTabBarItem? {
        return items[safe: selectedIndex]
    }
}
