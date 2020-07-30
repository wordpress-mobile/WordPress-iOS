import UIKit
import Gridicons
import Gutenberg

class GutenbergLayoutDisplayCategory {
    var category: GutenbergLayoutCategory
    var layouts: [GutenbergLayout]
    var scrollOffset: CGPoint

    init(category: GutenbergLayoutCategory, layouts: [GutenbergLayout], scrollOffset: CGPoint = .zero) {
        self.category = category
        self.layouts = layouts
        self.scrollOffset = scrollOffset
    }
}

class GutenbergLayoutPickerViewController: UIViewController {
    let categoryRowCellReuseIdentifier = "CategoryRowCell"

    @IBOutlet weak var headerBar: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var largeTitleView: UILabel!
    @IBOutlet weak var promptView: UILabel!
    @IBOutlet weak var categoryBar: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var createBlankPageBtn: UIButton!
    @IBOutlet weak var previewBtn: UIButton!
    @IBOutlet weak var createPageBtn: UIButton!

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

    /// Keeps track of the selected index path for cells. This treats section as the row in the table view and item as the selected index of the layout in the category.
    private var selectedLayoutIndexPath: IndexPath? = nil {
        didSet {
            layoutSelected(selectedLayoutIndexPath != nil)
        }
    }
    private var displayCategories = [GutenbergLayoutDisplayCategory]()
    var layouts = GutenbergPageLayouts(layouts: [], categories: []) {
        didSet {
            displayCategories = layouts.categories.map({
                GutenbergLayoutDisplayCategory(category: $0, layouts: layouts.layouts(forCategory: $0.slug))
            })
        }
    }

    var completion: PageCoordinator.TemplateSelectionCompletion? = nil

    private func setStaticText() {
        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "Dismisses the current screen")

        let translatedTitle = NSLocalizedString("Choose a Layout", comment: "Title for the screen to pick a template for a page")
        titleView.text = translatedTitle
        largeTitleView.text = translatedTitle

        promptView.text = NSLocalizedString("Get started by choosing from a wide variety of pre-made page layouts. Or just start with a blank page.", comment: "Prompt for the screen to pick a template for a page")
        createBlankPageBtn.setTitle(NSLocalizedString("Create Blank Page", comment: "Title for button to make a blank page"), for: .normal)
        previewBtn.setTitle(NSLocalizedString("Preview", comment: "Title for button to preview a selected layout"), for: .normal)
        createPageBtn.setTitle(NSLocalizedString("Create Page", comment: "Title for button to make a page with the contents of the selected layout"), for: .normal)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(LayoutPickerCategoryTableViewCell.nib, forCellReuseIdentifier: categoryRowCellReuseIdentifier)
        setStaticText()
        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)
        styleButtons()
        layoutHeader()
        layouts = GutenbergPageLayoutFactory.makeDefaultPageLayouts()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        super.viewDidDisappear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.isNavigationBarHidden = false
        super.prepare(for: segue, sender: sender)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                styleButtons()
            }
        }

        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            layoutTableViewHeader()
            if let visibleRow = tableView.indexPathsForVisibleRows?.first {
                tableView.scrollToRow(at: visibleRow, at: .top, animated: true)
            }
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

        [createBlankPageBtn, previewBtn].forEach { (button) in
            button?.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
            button?.layer.borderColor = seperator.cgColor
            button?.layer.borderWidth = 1
            button?.layer.cornerRadius = 8
        }

        createPageBtn.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
        createPageBtn.backgroundColor = accentColor
        createPageBtn.layer.cornerRadius = 8

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

    private func layoutTableViewHeader() {
        let tableFooterFrame = footerView.frame
        let bottomInset = tableFooterFrame.size.height
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: maxHeaderHeight + headerBar.frame.height))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: bottomInset))
    }

    private func calculateHeaderSnapPoints() {
        minHeaderHeight = categoryBar.frame.height + minHeaderBottomSpacing.constant
        _midHeaderHeight = titleToSubtitleSpacing.constant + promptView.frame.height + subtitleToCategoryBarSpacing.constant + categoryBar.frame.height + maxHeaderBottomSpacing.constant
        _midHeaderHeight = titleToSubtitleSpacing.constant + promptView.frame.height + subtitleToCategoryBarSpacing.constant + categoryBar.frame.height + maxHeaderBottomSpacing.constant
        _maxHeaderHeight = largeTitleView.frame.height + _midHeaderHeight
    }

    private func layoutHeader() {
        largeTitleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold)
        titleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(17)

        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        calculateHeaderSnapPoints()
        layoutTableViewHeader()

        let fillColor: UIColor
        if #available(iOS 13.0, *) {
            fillColor = .systemBackground
        } else {
            fillColor = .white
        }

        tableView.tableHeaderView?.backgroundColor = fillColor
        tableView.tableFooterView?.backgroundColor = fillColor
    }

    private func layoutSelected(_ isSelected: Bool) {
        createBlankPageBtn.isHidden = isSelected
        previewBtn.isHidden = !isSelected
        createPageBtn.isHidden = !isSelected
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDelegate {

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

extension GutenbergLayoutPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayCategories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: categoryRowCellReuseIdentifier, for: indexPath) as! LayoutPickerCategoryTableViewCell
        cell.delegate = self
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.displayCategory = displayCategories[indexPath.row]

        if let selectedLayoutIndexPath = selectedLayoutIndexPath, selectedLayoutIndexPath.section == indexPath.row {
            cell.selectItemAt(selectedLayoutIndexPath.item)
        }

        return cell
    }
}

extension GutenbergLayoutPickerViewController: LayoutPickerCategoryTableViewCellDelegate {

    func didSelectLayoutAt(_ position: Int, forCell cell: LayoutPickerCategoryTableViewCell) {
        guard let tableViewIndexPath = tableView.indexPath(for: cell) else { return }
        selectedLayoutIndexPath = IndexPath(item: position, section: tableViewIndexPath.row)
        tableView.selectRow(at: tableViewIndexPath, animated: false, scrollPosition: .none)
    }

    func didDeselectItem(forCell cell: LayoutPickerCategoryTableViewCell) {
        selectedLayoutIndexPath = nil
    }
}
