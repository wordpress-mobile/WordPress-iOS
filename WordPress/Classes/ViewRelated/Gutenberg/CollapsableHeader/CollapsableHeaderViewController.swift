import UIKit

protocol CollapsableHeaderDataSource {

    /// Used to populate the scrollable area of this container. 
    var scrollView: UIScrollView { get }

    /// Used to populate the Large title and small title in the header
    var mainTitle: String { get }

    /// Used to populate the subtitle/prompt in the header
    var prompt: String { get }

    /// Used to populate the button title for the button that is displayed when no item is selected
    var defaultActionTitle: String { get }

    /// Used to populate the button title for the right most button when an item is selected
    var primaryActionTitle: String { get }

    /// Used to populate the button title for the left most button when an item is selected
    var secondaryActionTitle: String { get }

    /// The estimated content size of the scroll view. This is used to adjust the content insests to allow the header to be scrollable to be collapsable still when
    /// it's not populated with enough data. This is desirable to help maintain the header's state when the filtered options change and reduce the content size.
    func estimatedContentSize() -> CGSize
}

protocol CollapsableHeaderDelegate: class {
    /// Notifies the delegate that the button that is displayed when no item is selected was tapped
    func defaultActionSelected()

    /// Notifies the delegate that the right most button when an item is selected was tapped
    func primaryActionSelected()

    /// Notifies the delegate that the left most button when an item is selected was tapped
    func secondaryActionSelected()
}

protocol CollapsableHeaderContentsDelegate: class {
    /// A public interface to notify the container that the content size of the scroll view is about to change. This is useful in adjusting the bottom insets to allow the
    /// view to still be scrollable with the content size is less than the total space of the expanded screen.
    func contentSizeWillChange()

    /// A public interface to notify the container that the selected state for an items has changed.
    func itemSelectionChanged(_ hasSelectedItem: Bool)

    /// A public interface to notify the container that the content view is loading content still
    func loadingStateChanged(_ isLoading: Bool)
}

class CollapsableHeaderViewController: UIViewController {

    let childViewController: (UIViewController & CollapsableHeaderDataSource)
    weak var delegate: CollapsableHeaderDelegate?
    weak var filterDelegate: CollapsableHeaderFilterBarDelegate?

    var scrollView: UIScrollView {
        childViewController.scrollView
    }

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var headerBar: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var largeTitleView: UILabel!
    @IBOutlet weak var promptView: UILabel!
    @IBOutlet weak var filterBar: CollapsableHeaderFilterBar!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var defaultActionButton: UIButton!
    @IBOutlet weak var secondaryActionButton: UIButton!
    @IBOutlet weak var primaryActionButton: UIButton!
    @IBOutlet weak var selectedStateButtonsContainer: UIView!

    /// This  is used as a means to adapt to different text sizes to force the desired layout and then active `headerHeightConstraint`
    /// when scrolling begins to allow pushing the non static items out of the scrollable area.
    @IBOutlet weak var initialHeaderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleToSubtitleSpacing: NSLayoutConstraint!
    @IBOutlet weak var subtitleToCategoryBarSpacing: NSLayoutConstraint!
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

    private var shouldUseCompactLayout: Bool {
        return traitCollection.verticalSizeClass == .compact
    }

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

    private var titleIsHidden: Bool = true {
        didSet {
            if oldValue != titleIsHidden {
                titleView.isHidden = false
                let alpha: CGFloat = titleIsHidden ? 0 : 1
                UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                    self.titleView.alpha = alpha
                }) { (_) in
                    self.titleView.isHidden = self.titleIsHidden
                }
            }
        }
    }

    var accentColor: UIColor {
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

    convenience init(childViewController: UIViewController & CollapsableHeaderDataSource & CollapsableHeaderDelegate & CollapsableHeaderFilterBarDelegate) {
        self.init(childViewController: childViewController, delegate: childViewController, filterDelegate: childViewController)
    }

    init(childViewController: UIViewController & CollapsableHeaderDataSource, delegate: CollapsableHeaderDelegate?, filterDelegate: CollapsableHeaderFilterBarDelegate?) {
        self.childViewController = childViewController
        self.delegate = delegate
        self.filterDelegate = filterDelegate
        super.init(nibName: "\(CollapsableHeaderViewController.self)", bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        insertChildView()

        largeTitleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold)
        titleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(17)
        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)

        styleButtons()
        setStaticText()

        scrollView.delegate = self
        layoutHeader()
        filterBar.filterDelegate = filterDelegate

        if #available(iOS 13.0, *) {} else {
            headerBar.backgroundColor = .basicBackground
            headerView.backgroundColor = .basicBackground
            footerView.backgroundColor = .basicBackground
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        super.viewDidDisappear(animated)
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
        }
    }

    @IBAction func closeSelected(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func defaultActionSelected(_ sender: Any) {
        delegate?.defaultActionSelected()
    }

    @IBAction func primaryActionSelected(_ sender: Any) {
        delegate?.primaryActionSelected()
    }

    @IBAction func secondaryActionSelected(_ sender: Any) {
        delegate?.secondaryActionSelected()
    }

    private func setStaticText() {
        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "Dismisses the current screen")
        titleView.text = childViewController.mainTitle
        largeTitleView.text = childViewController.mainTitle
        promptView.text = childViewController.prompt
        defaultActionButton.setTitle(childViewController.defaultActionTitle, for: .normal)
        secondaryActionButton.setTitle(childViewController.secondaryActionTitle, for: .normal)
        primaryActionButton.setTitle(childViewController.primaryActionTitle, for: .normal)
    }

    private func insertChildView() {
        add(childViewController)
        guard let childView = childViewController.view else { return }
        childView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: childView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 1)
        let bottom = NSLayoutConstraint(item: childView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 1)
        let leading = NSLayoutConstraint(item: childView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 1)
        let trailing = NSLayoutConstraint(item: childView, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: 1)
        containerView.addSubview(childView)
        containerView.addConstraints([top, bottom, leading, trailing])
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

        if #available(iOS 13.0, *) {
            closeButton.backgroundColor = UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.systemFill
                } else {
                    return UIColor.quaternarySystemFill
                }
            }
        }
    }

    private func calculateHeaderSnapPoints() {
        minHeaderHeight = filterBar.frame.height + minHeaderBottomSpacing.constant
        _midHeaderHeight = titleToSubtitleSpacing.constant + promptView.frame.height + subtitleToCategoryBarSpacing.constant + filterBar.frame.height + maxHeaderBottomSpacing.constant
        _maxHeaderHeight = largeTitleView.frame.height + _midHeaderHeight
    }

    private func layoutHeaderInsets() {
        let topInset: CGFloat

        if #available(iOS 13.0, *) {
            topInset = maxHeaderHeight + headerBar.frame.height
        } else {
            topInset = maxHeaderHeight + headerBar.frame.height + UIApplication.shared.statusBarFrame.height
        }

        if let tableView = scrollView as? UITableView {
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: topInset))
            tableView.tableHeaderView?.backgroundColor = .clear
        } else {
            scrollView.contentInset.top = topInset
        }

        updateFooterInsets()
    }

    /*
     * Calculates the needed space for the footer to allow the header to still collapse but also to prevent unneeded space
     * at the bottome of the tableView when multiple cells are rendered.
     */
    private func updateFooterInsets() {
        let minimumFooterSize = footerView.frame.size.height + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)

        /// The needed distance to fill the rest of the screen to allow the header to still collapse when scrolling (or to maintain a collapsed header if it was already collapsed when selecting a filter)
        let estimatedContentSize = childViewController.estimatedContentSize()
        let distanceToBottom = scrollView.frame.height - headerBar.frame.height - minHeaderHeight - estimatedContentSize.height
        let newHeight: CGFloat = max(minimumFooterSize, distanceToBottom)

        if let tableView = scrollView as? UITableView {
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: newHeight))
            tableView.tableFooterView?.isGhostableDisabled = true
            tableView.tableFooterView?.backgroundColor = .clear
        } else {
            scrollView.contentInset.bottom = newHeight
        }
    }

    private func layoutHeader() {
        [headerBar, headerView, footerView].forEach({
            $0?.setNeedsLayout()
            $0?.layoutIfNeeded()
        })

        calculateHeaderSnapPoints()
        layoutHeaderInsets()
    }
}

extension CollapsableHeaderViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !shouldUseCompactLayout else {
            titleIsHidden = false
            return
        }

        if !headerHeightConstraint.isActive {
            initialHeaderTopConstraint.isActive = false
            headerHeightConstraint.isActive = true
        }

        let scrollOffset = scrollView.contentOffset.y
        let newHeaderViewHeight = maxHeaderHeight - scrollOffset

        if newHeaderViewHeight < minHeaderHeight {
            headerHeightConstraint.constant = minHeaderHeight
        } else {
            headerHeightConstraint.constant = newHeaderViewHeight
        }

        titleIsHidden = largeTitleView.frame.maxY > 0
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

    private func snapToHeight(_ scrollView: UIScrollView, height: CGFloat) {
        scrollView.contentOffset.y = maxHeaderHeight - height
        headerHeightConstraint.constant = height
        titleIsHidden = (height >= maxHeaderHeight) && !shouldUseCompactLayout
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.headerView.setNeedsLayout()
            self.headerView.layoutIfNeeded()
        }, completion: nil)
    }
}

extension CollapsableHeaderViewController: CollapsableHeaderContentsDelegate {

    func contentSizeWillChange() {
        updateFooterInsets()
    }

    func itemSelectionChanged(_ hasSelectedItem: Bool) {
        defaultActionButton.isHidden = false
        selectedStateButtonsContainer.isHidden = false

        defaultActionButton.alpha = hasSelectedItem ? 1 : 0
        selectedStateButtonsContainer.alpha = hasSelectedItem ? 0 : 1

        let alpha: CGFloat = hasSelectedItem ? 0 : 1
        let selectedStateContainerAlpha: CGFloat = hasSelectedItem ? 1 : 0

        UIView.animate(withDuration: LayoutPickerCollectionViewCell.selectionAnimationSpeed, delay: 0, options: .transitionCrossDissolve, animations: {
            self.defaultActionButton.alpha = alpha
            self.selectedStateButtonsContainer.alpha = selectedStateContainerAlpha
        }) { (_) in
            self.defaultActionButton.isHidden = hasSelectedItem
            self.selectedStateButtonsContainer.isHidden = !hasSelectedItem
        }
    }

    func loadingStateChanged(_ isLoading: Bool) {
        filterBar.shouldShowGhostContent = isLoading
        filterBar.allowsMultipleSelection = !isLoading
        filterBar.reloadData()
    }
}
