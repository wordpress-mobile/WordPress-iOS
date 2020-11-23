import UIKit
import WordPressUI

class CollapsableHeaderViewController: UIViewController, NoResultsViewHost {
    enum SeperatorStyle {
        case visibile
        case automatic
        case hidden
    }

    let scrollableView: UIScrollView
    let accessoryView: UIView?
    let mainTitle: String
    let prompt: String
    let primaryActionTitle: String
    let secondaryActionTitle: String?
    let defaultActionTitle: String?
    open var accessoryBarHeight: CGFloat {
        return 44
    }

    open var seperatorStyle: SeperatorStyle {
        return self.hasAccessoryBar ? .visibile : .automatic
    }

    private let hasDefaultAction: Bool

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var headerView: UIView!
    let titleView: UILabel = {
        let title = UILabel(frame: .zero)
        title.adjustsFontForContentSizeCategory = true
        title.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(17)
        title.isHidden = true
        return title
    }()
    @IBOutlet weak var largeTitleTopSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var largeTitleView: UILabel!
    @IBOutlet weak var promptView: UILabel!
    @IBOutlet weak var accessoryBar: UIView!
    @IBOutlet weak var accessoryBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var defaultActionButton: UIButton!
    @IBOutlet weak var secondaryActionButton: UIButton!
    @IBOutlet weak var primaryActionButton: UIButton!
    @IBOutlet weak var selectedStateButtonsContainer: UIStackView!
    @IBOutlet weak var seperator: UIView!

    /// This  is used as a means to adapt to different text sizes to force the desired layout and then active `headerHeightConstraint`
    /// when scrolling begins to allow pushing the non static items out of the scrollable area.
    @IBOutlet weak var initialHeaderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleToSubtitleSpacing: NSLayoutConstraint!
    @IBOutlet weak var subtitleToCategoryBarSpacing: NSLayoutConstraint!

    /// As the Header expands it allows a little bit of extra room between the bottom of the filter bar and the bottom of the header view. These next two constaints help account for that slight adustment.
    @IBOutlet weak var minHeaderBottomSpacing: NSLayoutConstraint!
    @IBOutlet weak var maxHeaderBottomSpacing: NSLayoutConstraint!

    @IBOutlet var visualEffects: [UIVisualEffectView]! {
        didSet {
            if #available(iOS 13.0, *) {
                visualEffects.forEach { (visualEffect) in
                    visualEffect.effect = UIBlurEffect.init(style: .systemChromeMaterial)
                }
            }
        }
    }
    private var footerHeight: CGFloat {
        let verticalMargins: CGFloat = 16
        let buttonHeight: CGFloat = 44
        let safeArea = (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
        return verticalMargins + buttonHeight + verticalMargins + safeArea
    }
    private var isShowingNoResults: Bool = false {
        didSet {
            if oldValue != isShowingNoResults {
                updateHeaderDisplay()
            }
        }
    }

    private let hasAccessoryBar: Bool
    private var shouldHideAccessoryBar: Bool {
        return isShowingNoResults || !hasAccessoryBar
    }

    private var shouldUseCompactLayout: Bool {
        return traitCollection.verticalSizeClass == .compact
    }

    private var topInset: CGFloat = 0
    private var _maxHeaderHeight: CGFloat = 0
    private var maxHeaderHeight: CGFloat {
        if shouldUseCompactLayout {
            return minHeaderHeight
        } else {
            return _maxHeaderHeight
        }
    }

    private var _midHeaderHeight: CGFloat = 0
    private var midHeaderHeight: CGFloat {
        if shouldUseCompactLayout {
            return minHeaderHeight
        } else {
            return _midHeaderHeight
        }
    }
    private var minHeaderHeight: CGFloat = 0

    private var accentColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.muriel(color: .accent, .shade40)
                } else {
                    return UIColor.muriel(color: .accent, .shade50)
                }
            }
        } else {
            return UIColor.muriel(color: .accent, .shade50)
        }
    }

    // MARK: - Static Helpers
    public static func closeButton(target: Any?, action: Selector) -> UIBarButtonItem {
        let closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        closeButton.layer.cornerRadius = 15
        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "Dismisses the current screen")
        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)
        closeButton.addTarget(target, action: action, for: .touchUpInside)

        if #available(iOS 13.0, *) {
            closeButton.tintColor = .secondaryLabel
            closeButton.backgroundColor = UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.systemFill
                } else {
                    return UIColor.quaternarySystemFill
                }
            }
        } else {
            closeButton.tintColor = .textSubtle
            closeButton.backgroundColor = .quaternaryBackground
        }

        return UIBarButtonItem(customView: closeButton)
    }

    // MARK: - Initializers
    /// Configure and display the no results view controller
    ///
    /// - Parameters:
    ///   - scrollableView: Populates the scrollable area of this container. Required.
    ///   - title: The Large title and small title in the header. Required.
    ///   - prompt: The subtitle/prompt in the header. Required.
    ///   - primaryActionTitle: The button title for the right most button when an item is selected. Required.
    ///   - secondaryActionTitle: The button title for the left most button when an item is selected. Optional - nil results in the left most button being hidden when an item is selected.
    ///   - defaultActionTitle: The button title for the button that is displayed when no item is selected. Optional - nil results in the footer being hidden when no item is selected.
    ///   - accessoryView: The view to be placed in the placeholder of the accessory bar. Optional - The default is nil.
    ///
    init(scrollableView: UIScrollView,
         mainTitle: String,
         prompt: String,
         primaryActionTitle: String,
         secondaryActionTitle: String? = nil,
         defaultActionTitle: String? = nil,
         accessoryView: UIView? = nil) {
        self.scrollableView = scrollableView
        self.mainTitle = mainTitle
        self.prompt = prompt
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = secondaryActionTitle
        self.defaultActionTitle = defaultActionTitle
        self.hasAccessoryBar = (accessoryView != nil)
        self.hasDefaultAction = (defaultActionTitle != nil)
        self.accessoryView = accessoryView
        super.init(nibName: "\(CollapsableHeaderViewController.self)", bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        insertChildView()
        insertAccessoryView()
        navigationItem.titleView = titleView
        largeTitleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold)
        toggleFilterBarConstraints()
        styleButtons()
        setStaticText()
        scrollableView.delegate = self

        if #available(iOS 13.0, *) {} else {
            headerView.backgroundColor = .basicBackground
            footerView.backgroundColor = .basicBackground
        }
        formatNavigationController()
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .top
        updateSeperatorStyle()
    }

    /// The estimated content size of the scroll view. This is used to adjust the content insests to allow the header to be scrollable to be collapsable still when
    /// it's not populated with enough data. This is desirable to help maintain the header's state when the filtered options change and reduce the content size.
    open func estimatedContentSize() -> CGSize {
        return scrollableView.contentSize
    }

    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 13.0, *) {
            // For iOS 13 the navigation item is being set so there is no need to reconfigure it everytime we're displaying a controller.
        } else {
            formatNavigationController()
        }
        if !isViewOnScreen() {
            layoutHeader()
        }
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        if #available(iOS 13.0, *) {
            // For iOS 13 the navigation item is being set so there is no need to revert everytime we're dismissing the controller.
        } else {
            restoreNavigationBar()
        }
        super.viewWillDisappear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard isShowingNoResults else { return }
        coordinator.animate(alongsideTransition: nil) { (_) in
            self.updateHeaderDisplay()
            if self.shouldHideAccessoryBar {
                self.disableInitialLayoutHelpers()
                self.snapToHeight(self.scrollableView, height: self.minHeaderHeight, animated: false)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                styleButtons()
            }
        }

        if let previousTraitCollection = previousTraitCollection, traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass {
            layoutHeaderInsets()

            // This helps reset the header changes after a rotation.
            scrollViewDidScroll(scrollableView)
            scrollViewDidEndDecelerating(scrollableView)
        }
    }

    // MARK: - Footer Actions
    @IBAction open func defaultActionSelected(_ sender: Any) {
        /* This should be overriden in a child class in order to enable support. */
    }

    @IBAction open func primaryActionSelected(_ sender: Any) {
        /* This should be overriden in a child class in order to enable support. */
    }

    @IBAction open func secondaryActionSelected(_ sender: Any) {
        /* This should be overriden in a child class in order to enable support. */
    }

    // MARK: - Format Nav Bar
    /*
     * To allow more flexibility in the navigation bar's header items, we keep the navigation bar available.
     * However, that space is also essential to a uniform design of the header. This function updates the design of the
     * navigation bar. On iOS 13+, we're able to set the design to the `navigationItem`, which is ViewController specific.
     * On iOS 12 and below, we need to set those values to the `navigationBar`. We cache the original values in
     * `originalNavBarAppearance` and then revert the changes when the view is dismissed by calling `restoreNavigationBar`
     */
    private func formatNavigationController() {
        if #available(iOS 13.0, *) {
            let newAppearance = UINavigationBarAppearance()
            newAppearance.configureWithTransparentBackground()
            newAppearance.backgroundColor = .clear
            newAppearance.shadowColor = .clear
            newAppearance.shadowImage = UIImage()
            navigationItem.standardAppearance = newAppearance
            navigationItem.scrollEdgeAppearance = newAppearance
            navigationItem.compactAppearance = newAppearance
        } else {
            if originalNavBarAppearance == nil {
                cacheNavBarAppearance()
            }

            navigationController?.navigationBar.barStyle = .default
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.shadowImage = UIImage()
        }

        setNeedsStatusBarAppearanceUpdate()
    }

    @available(iOS, obsoleted: 13.0, message: "See description on `formatNavigationController`")
    private var originalNavBarAppearance: (barStyle: UIBarStyle, barTintColor: UIColor?, isTranslucent: Bool, shadowImage: UIImage?)?

    @available(iOS, obsoleted: 13.0, message: "See description on `formatNavigationController`")
    private func cacheNavBarAppearance() {
        if #available(iOS 13.0, *) { } else {
            originalNavBarAppearance = (navigationController?.navigationBar.barStyle ?? .default,
                                        navigationController?.navigationBar.barTintColor,
                                        navigationController?.navigationBar.isTranslucent ?? true,
                                        navigationController?.navigationBar.shadowImage)
        }
    }

    @available(iOS, obsoleted: 13.0, message: "See description on `formatNavigationController`")
    private func restoreNavigationBar() {
        if #available(iOS 13.0, *) { } else {
            navigationController?.navigationBar.barStyle = originalNavBarAppearance?.barStyle ?? .default
            navigationController?.navigationBar.barTintColor = originalNavBarAppearance?.barTintColor
            navigationController?.navigationBar.isTranslucent = originalNavBarAppearance?.isTranslucent ?? true
            navigationController?.navigationBar.shadowImage = originalNavBarAppearance?.shadowImage
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    // MARK: - View Styling
    private func setStaticText() {
        titleView.text = mainTitle
        titleView.sizeToFit()
        largeTitleView.text = mainTitle
        promptView.text = prompt
        primaryActionButton.setTitle(primaryActionTitle, for: .normal)

        if let defaultActionTitle = defaultActionTitle {
            defaultActionButton.setTitle(defaultActionTitle, for: .normal)
        } else {
            footerHeightContraint.constant = 0
            footerView.layoutIfNeeded()
            defaultActionButton.isHidden = true
            selectedStateButtonsContainer.isHidden = false
        }

        if let secondaryActionTitle = secondaryActionTitle {
            secondaryActionButton.setTitle(secondaryActionTitle, for: .normal)
        } else {
            secondaryActionButton.isHidden = true
        }
    }

    private func insertChildView() {
        scrollableView.translatesAutoresizingMaskIntoConstraints = false
        scrollableView.clipsToBounds = false
        let top = NSLayoutConstraint(item: scrollableView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: scrollableView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: scrollableView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: scrollableView, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: 0)
        containerView.addSubview(scrollableView)
        containerView.addConstraints([top, bottom, leading, trailing])
    }

    private func insertAccessoryView() {
        guard let accessoryView = accessoryView else { return }
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: accessoryView, attribute: .top, relatedBy: .equal, toItem: accessoryBar, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: accessoryView, attribute: .bottom, relatedBy: .equal, toItem: accessoryBar, attribute: .bottom, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: accessoryView, attribute: .leading, relatedBy: .equal, toItem: accessoryBar, attribute: .leading, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: accessoryView, attribute: .trailing, relatedBy: .equal, toItem: accessoryBar, attribute: .trailing, multiplier: 1, constant: 0)
        accessoryBar.addSubview(accessoryView)
        accessoryBar.addConstraints([top, bottom, leading, trailing])
    }

    private func styleButtons() {
        let seperator: UIColor
        if #available(iOS 13.0, *) {
            seperator = .separator
        } else {
            seperator = UIColor.muriel(color: .divider)
        }

        [defaultActionButton, secondaryActionButton].forEach { (button) in
            button?.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
            button?.layer.borderColor = seperator.cgColor
            button?.layer.borderWidth = 1
            button?.layer.cornerRadius = 8
        }

        primaryActionButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
        primaryActionButton.backgroundColor = accentColor
        primaryActionButton.layer.cornerRadius = 8
    }

    // MARK: - Header and Footer Sizing
    private func toggleFilterBarConstraints() {
        accessoryBarHeightConstraint.constant = shouldHideAccessoryBar ? 0 : accessoryBarHeight
        let collapseBottomSpacing = shouldHideAccessoryBar || (seperatorStyle == .hidden)
        maxHeaderBottomSpacing.constant = collapseBottomSpacing ? 1 : 24
        minHeaderBottomSpacing.constant = collapseBottomSpacing ? 1 : 9
    }

    private func updateHeaderDisplay() {
        headerHeightConstraint.isActive = false
        initialHeaderTopConstraint.isActive = true
        toggleFilterBarConstraints()
        accessoryBar.layoutIfNeeded()
        headerView.layoutIfNeeded()
        calculateHeaderSnapPoints()
        layoutHeaderInsets()
    }

    private func calculateHeaderSnapPoints() {
        let accessoryBarSpacing: CGFloat
        if shouldHideAccessoryBar {
            minHeaderHeight = 1
            accessoryBarSpacing = minHeaderHeight
        } else {
            minHeaderHeight = accessoryBarHeightConstraint.constant + minHeaderBottomSpacing.constant
            accessoryBarSpacing = accessoryBarHeightConstraint.constant + maxHeaderBottomSpacing.constant
        }
        _midHeaderHeight = titleToSubtitleSpacing.constant + promptView.frame.height + subtitleToCategoryBarSpacing.constant + accessoryBarSpacing
        _maxHeaderHeight = largeTitleTopSpacingConstraint.constant + largeTitleView.frame.height + _midHeaderHeight
    }

    private func layoutHeaderInsets() {
        let topInset: CGFloat = maxHeaderHeight
        if let tableView = scrollableView as? UITableView {
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: topInset))
            tableView.tableHeaderView?.backgroundColor = .clear
        } else {
            self.topInset = topInset
            scrollableView.contentInset.top = topInset
        }

        updateFooterInsets()
    }

    /*
     * Calculates the needed space for the footer to allow the header to still collapse but also to prevent unneeded space
     * at the bottome of the tableView when multiple cells are rendered.
     */
    private func updateFooterInsets() {
        /// Update the footer height if it's being displayed. 
        if footerHeightContraint.constant > 0 {
            footerHeightContraint.constant = footerHeight
        }

        /// The needed distance to fill the rest of the screen to allow the header to still collapse when scrolling (or to maintain a collapsed header if it was already collapsed when selecting a filter)
        let distanceToBottom = scrollableView.frame.height - minHeaderHeight - estimatedContentSize().height
        let newHeight: CGFloat = max(footerHeight, distanceToBottom)
        if let tableView = scrollableView as? UITableView {
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: newHeight))
            tableView.tableFooterView?.isGhostableDisabled = true
            tableView.tableFooterView?.backgroundColor = .clear
        } else {
            scrollableView.contentInset.bottom = newHeight
        }
    }

    private func layoutHeader() {
        [headerView, footerView].forEach({
            $0?.setNeedsLayout()
            $0?.layoutIfNeeded()
        })

        calculateHeaderSnapPoints()
        layoutHeaderInsets()
        updateTitleViewVisibility(false)
    }

    // MARK: - Subclass callbacks

    /// A public interface to notify the container that the content has loaded data or is attempting too.
    public func displayNoResultsController(title: String, subtitle: String?, resultsDelegate: NoResultsViewControllerDelegate?) {
        guard !isShowingNoResults else { return }
        isShowingNoResults = true
        disableInitialLayoutHelpers()
        snapToHeight(scrollableView, height: minHeaderHeight)
        configureAndDisplayNoResults(on: containerView,
                                     title: title,
                                     subtitle: subtitle,
                                     noConnectionSubtitle: subtitle,
                                     buttonTitle: NSLocalizedString("Retry", comment: "A prompt to attempt the failed network request again"),
                                     customizationBlock: { (noResultsController) in
                                        noResultsController.delegate = resultsDelegate
                                     })
    }

    public func dismissNoResultsController() {
        guard isShowingNoResults else { return }
        isShowingNoResults = false
        snapToHeight(scrollableView, height: maxHeaderHeight)
        hideNoResults()
    }

    /// In scenarios where the content offset before content changes doesn't align with the available space after the content changes then the offset can be lost. In
    /// order to preserve the header's collpased state we cache the offset and attempt to reapply it if needed.
    private var stashedOffset: CGPoint? = nil

    /// A public interface to notify the container that the content size of the scroll view is about to change. This is useful in adjusting the bottom insets to allow the
    /// view to still be scrollable with the content size is less than the total space of the expanded screen.
    public func contentSizeWillChange() {
        stashedOffset = scrollableView.contentOffset
        updateFooterInsets()
    }

    /// A public interface to notify the container that the selected state for an items has changed.
    public func itemSelectionChanged(_ hasSelectedItem: Bool) {
        let animationSpeed = CollapsableHeaderCollectionViewCell.selectionAnimationSpeed
        guard hasDefaultAction else {
            UIView.animate(withDuration: animationSpeed, delay: 0, options: .curveEaseInOut, animations: {
                self.footerHeightContraint.constant = hasSelectedItem ? self.footerHeight : 0
                self.footerView.setNeedsLayout()
                self.footerView.layoutIfNeeded()
            })
            return
        }

        defaultActionButton.isHidden = false
        selectedStateButtonsContainer.isHidden = false

        defaultActionButton.alpha = hasSelectedItem ? 1 : 0
        selectedStateButtonsContainer.alpha = hasSelectedItem ? 0 : 1

        let alpha: CGFloat = hasSelectedItem ? 0 : 1
        let selectedStateContainerAlpha: CGFloat = hasSelectedItem ? 1 : 0

        UIView.animate(withDuration: animationSpeed, delay: 0, options: .transitionCrossDissolve, animations: {
            self.defaultActionButton.alpha = alpha
            self.selectedStateButtonsContainer.alpha = selectedStateContainerAlpha
        }) { (_) in
            self.defaultActionButton.isHidden = hasSelectedItem
            self.selectedStateButtonsContainer.isHidden = !hasSelectedItem
        }
    }

    // MARK: - Seperator styling
    private func updateSeperatorStyle(animated: Bool = true) {
        let shouldBeHidden: Bool
        switch seperatorStyle {
        case .automatic:
            shouldBeHidden = headerHeightConstraint.constant > minHeaderHeight && !shouldUseCompactLayout
        case .visibile:
            shouldBeHidden = false
        case .hidden:
            shouldBeHidden = true
        }

        seperator.animatableSetIsHidden(shouldBeHidden, animated: animated)
    }
}

// MARK: - UIScrollViewDelegate
extension CollapsableHeaderViewController: UIScrollViewDelegate {

    private func disableInitialLayoutHelpers() {
        if !headerHeightConstraint.isActive {
            initialHeaderTopConstraint.isActive = false
            headerHeightConstraint.isActive = true
        }
    }

    /// Restores the stashed content offset if it appears as if it's been reset.
    private func restoreContentOffsetIfNeeded(_ scrollView: UIScrollView) {
        guard var stashedOffset = stashedOffset else { return }
        stashedOffset = resolveContentOffsetCollisions(scrollView, cachedOffset: stashedOffset)
        scrollView.contentOffset = stashedOffset
    }

    private func resolveContentOffsetCollisions(_ scrollView: UIScrollView, cachedOffset: CGPoint) -> CGPoint {
        var adjustedOffset = cachedOffset

        /// If the content size has changed enough to where the cached offset would scroll beyond the allowable bounds then we reset to the minum scroll height to
        /// maintain the header's size.
        if scrollView.contentSize.height - cachedOffset.y < scrollView.frame.height {
            adjustedOffset.y = maxHeaderHeight - headerHeightConstraint.constant
            stashedOffset = adjustedOffset
        }

        return adjustedOffset
    }

    private func resizeHeaderIfNeeded(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y + topInset
        let newHeaderViewHeight = maxHeaderHeight - scrollOffset

        if newHeaderViewHeight < minHeaderHeight {
            headerHeightConstraint.constant = minHeaderHeight
        } else {
            headerHeightConstraint.constant = newHeaderViewHeight
        }
    }

    private func updateTitleViewVisibility(_ animated: Bool = true) {
        let shouldHide = (headerHeightConstraint.constant > midHeaderHeight) && !shouldUseCompactLayout
        titleView.animatableSetIsHidden(shouldHide, animated: animated)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        /// Clear the stashed offset because the user has initiated a change
        stashedOffset = nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard stashedOffset == nil else {
            restoreContentOffsetIfNeeded(scrollView)
            return
        }

        guard !shouldUseCompactLayout,
              !isShowingNoResults else {
            updateTitleViewVisibility(true)
            updateSeperatorStyle()
            return
        }
        disableInitialLayoutHelpers()
        resizeHeaderIfNeeded(scrollView)
        updateTitleViewVisibility()
        updateSeperatorStyle()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToHeight(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            snapToHeight(scrollView)
        }
    }

    private func snapToHeight(_ scrollView: UIScrollView) {
        guard !shouldUseCompactLayout else { return }

        if largeTitleView.frame.midY > 0 {
            snapToHeight(scrollView, height: maxHeaderHeight)
        } else if promptView.frame.midY > 0 {
            snapToHeight(scrollView, height: midHeaderHeight)
        } else if headerHeightConstraint.constant != minHeaderHeight {
            snapToHeight(scrollView, height: minHeaderHeight)
        }
    }

    private func snapToHeight(_ scrollView: UIScrollView, height: CGFloat, animated: Bool = true) {
        scrollView.contentOffset.y = maxHeaderHeight - height - topInset
        headerHeightConstraint.constant = height
        updateTitleViewVisibility(animated)
        updateSeperatorStyle(animated: animated)

        guard animated else {
            headerView.setNeedsLayout()
            headerView.layoutIfNeeded()
            return
        }
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.headerView.setNeedsLayout()
            self.headerView.layoutIfNeeded()
        }, completion: nil)
    }
}
