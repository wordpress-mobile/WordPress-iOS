import UIKit
import Gridicons

class GutenbergLayoutPickerViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var largeTitleView: UILabel!
    @IBOutlet weak var promptView: UILabel!
    @IBOutlet weak var categoryBar: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var createBlankPageBtn: UIButton!

    /// This  is used as a means to adapt to different text sizes to force the desired layout and then active `headerHeightConstraint`
    /// when scrolling begins to allow pushing the non static items out of the scrollable area.
    @IBOutlet weak var initialHeaderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleToSubtitleSpacing: NSLayoutConstraint!
    @IBOutlet weak var subtitleToCategoryBarSpacing: NSLayoutConstraint!
    @IBOutlet weak var minHeaderBottomSpacing: NSLayoutConstraint!
    @IBOutlet weak var maxHeaderBottomSpacing: NSLayoutConstraint!

    var completion: PageCoordinator.TemplateSelectionCompletion? = nil

    private var shouldUseCompactLayout: Bool {
        return traitCollection.verticalSizeClass == .compact
    }

    private var maxHeaderHeight: CGFloat {
        if shouldUseCompactLayout {
            return minHeaderHeight
        } else {
            return largeTitleView.frame.height +
                midHeaderHeight
        }
    }
    private var midHeaderHeight: CGFloat {
        if shouldUseCompactLayout {
            return minHeaderHeight
        } else {
            return titleToSubtitleSpacing.constant +
                promptView.frame.height +
                subtitleToCategoryBarSpacing.constant +
                categoryBar.frame.height +
                maxHeaderBottomSpacing.constant
        }
    }
    private var minHeaderHeight: CGFloat {
        return categoryBar.frame.height + minHeaderBottomSpacing.constant
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)
        styleButtons()
        layoutHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        (navigationController as? GutenbergLightNavigationController)?.shadowIsHidden = true
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        (navigationController as? GutenbergLightNavigationController)?.shadowIsHidden = false
        super.viewDidDisappear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (navigationController as? GutenbergLightNavigationController)?.shadowIsHidden = false
        super.prepare(for: segue, sender: sender)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                styleButtons()
            }
        }

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            headerView.invalidateIntrinsicContentSize()
            largeTitleView.invalidateIntrinsicContentSize()
        }
    }

    @IBAction func closeModal(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func createBlankPage(_ sender: Any) {
        createPage(nil)
    }

    private func createPage(_ template: String?) {
        guard let completion = completion else {
            dismiss(animated: true, completion: nil)
            return
        }

        dismiss(animated: true) {
            completion(template)
        }
    }

    private func styleButtons() {
        let seperator: UIColor
        if #available(iOS 13.0, *) {
            seperator = .separator
        } else {
            seperator = .lightGray
        }

        [createBlankPageBtn].forEach { (button) in
            button?.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
            button?.layer.borderColor = seperator.cgColor
            button?.layer.borderWidth = 1
            button?.layer.cornerRadius = 8
        }

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

    private func layoutHeader() {
        largeTitleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold)
        titleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(17)

        headerHeightConstraint.constant = maxHeaderHeight
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        let tableFooterFrame = footerView.frame
        let bottomInset = tableFooterFrame.size.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 44)

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: maxHeaderHeight))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: bottomInset))
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard !shouldUseCompactLayout && !headerHeightConstraint.isActive else { return }

        headerHeightConstraint.isActive = true
        initialHeaderTopConstraint.isActive = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !shouldUseCompactLayout else { return }

        let scrollOffset = scrollView.contentOffset.y
        let newHeaderViewHeight = maxHeaderHeight - scrollOffset

        if newHeaderViewHeight < minHeaderHeight {
            headerHeightConstraint.constant = minHeaderHeight
        } else {
            headerHeightConstraint.constant = newHeaderViewHeight
        }

        titleView.isHidden = largeTitleView.frame.maxY > 0
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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
        titleView.isHidden = (height >= maxHeaderHeight) && !shouldUseCompactLayout
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.headerView.setNeedsLayout()
            self.headerView.layoutIfNeeded()
        }, completion: nil)
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20 // This is a random number chossen for testing
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 318 // This is an estimated number for the height of the eventual cells. Being used for testing right now.
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        return cell
    }
}
