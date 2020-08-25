import UIKit
import Gridicons
import Gutenberg

class GutenbergLayoutSection {
    var section: GutenbergLayoutCategory
    var layouts: [GutenbergLayout]
    var scrollOffset: CGPoint

    init(section: GutenbergLayoutCategory, layouts: [GutenbergLayout], scrollOffset: CGPoint = .zero) {
        self.section = section
        self.layouts = layouts
        self.scrollOffset = scrollOffset
    }
}

struct GutenbergSelectedLayout {
    let sectionSlug: String
    let position: Int
}

class GutenbergLayoutPickerViewController: UIViewController {

    @IBOutlet weak var headerBar: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var largeTitleView: UILabel!
    @IBOutlet weak var promptView: UILabel!
    @IBOutlet weak var filterBar: GutenbergLayoutFilterBar!
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

    private var selectedLayout: GutenbergSelectedLayout? = nil {
        didSet {
            layoutSelected(selectedLayout != nil)
        }
    }

    private var filteredSections: [GutenbergLayoutSection]?
    private var sections: [GutenbergLayoutSection] = []
    var layouts = GutenbergPageLayouts(layouts: [], categories: []) {
        didSet {
            sections = layouts.categories.map({
                GutenbergLayoutSection(section: $0, layouts: layouts.layouts(forCategory: $0.slug))
            })
        }
    }
    private var isLoading: Bool = true {
        didSet {
            filterBar.shouldShowGhostContent = isLoading
            filterBar.allowsMultipleSelection = !isLoading
            if isLoading {
                tableView.startGhostAnimation()
            } else {
                tableView.stopGhostAnimation()
            }

            tableView.reloadData()
            filterBar.reloadData()
        }
    }

    var completion: PageCoordinator.TemplateSelectionCompletion? = nil
    var blog: Blog? = nil

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
        tableView.register(LayoutPickerSectionTableViewCell.nib, forCellReuseIdentifier: LayoutPickerSectionTableViewCell.cellReuseIdentifier)
        filterBar.filterDelegate = self
        setStaticText()
        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)
        styleButtons()
        layoutHeader()
        layouts = GutenbergPageLayouts()
        fetchLayouts()
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

        if let previousTraitCollection = previousTraitCollection, traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass {
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
            seperator = UIColor.muriel(color: .divider)
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
        let bottomInset = tableFooterFrame.size.height + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: maxHeaderHeight + headerBar.frame.height))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: bottomInset))
        tableView.tableFooterView?.isGhostableDisabled = true
    }

    private func calculateHeaderSnapPoints() {
        minHeaderHeight = filterBar.frame.height + minHeaderBottomSpacing.constant
        _midHeaderHeight = titleToSubtitleSpacing.constant + promptView.frame.height + subtitleToCategoryBarSpacing.constant + filterBar.frame.height + maxHeaderBottomSpacing.constant
        _maxHeaderHeight = largeTitleView.frame.height + _midHeaderHeight
    }

    private func layoutHeader() {
        largeTitleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold)
        titleView.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(17)

        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        footerView.setNeedsLayout()
        footerView.layoutIfNeeded()

        calculateHeaderSnapPoints()
        layoutTableViewHeader()

        tableView.tableHeaderView?.backgroundColor = .clear
        tableView.tableFooterView?.backgroundColor = .clear
    }

    private func layoutSelected(_ isSelected: Bool) {
        createBlankPageBtn.isHidden = isSelected
        previewBtn.isHidden = !isSelected
        createPageBtn.isHidden = !isSelected
    }

    private func fetchLayouts() {
        guard let blog = blog else { return }
        isLoading = true
        PageLayoutService.layouts(forBlog: blog) {[weak self] (results) in
            guard let self = self else { return }
            switch results {
            case .success(let fetchedLayouts):
                self.layouts = fetchedLayouts
                self.isLoading = false
            case .failure:
                return
            }
        }
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

    private func containsSelectedLayout(_ layout: GutenbergSelectedLayout, atIndexPath indexPath: IndexPath) -> Bool {
        let rowSection = (filteredSections ?? sections)[indexPath.row]
        return (layout.sectionSlug == rowSection.section.slug)
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isLoading ? 1 : ((filteredSections ?? sections).count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellReuseIdentifier = LayoutPickerSectionTableViewCell.cellReuseIdentifier
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? LayoutPickerSectionTableViewCell else {
            fatalError("Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(LayoutPickerSectionTableViewCell.self). Please make sure the table view is registering the correct nib before loading the data")
        }
        cell.delegate = self
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.section = isLoading ? nil : (filteredSections ?? sections)[indexPath.row]
        cell.isGhostCell = isLoading
        cell.layer.masksToBounds = false
        cell.clipsToBounds = false
        cell.collectionView.allowsSelection = !isLoading
        if let selectedLayout = selectedLayout, containsSelectedLayout(selectedLayout, atIndexPath: indexPath) {
            cell.selectItemAt(selectedLayout.position)
        }

        return cell
    }
}

extension GutenbergLayoutPickerViewController: LayoutPickerSectionTableViewCellDelegate {

    func didSelectLayoutAt(_ position: Int, forCell cell: LayoutPickerSectionTableViewCell) {
        guard let cellIndexPath = tableView.indexPath(for: cell), let slug = cell.section?.section.slug else { return }
        tableView.selectRow(at: cellIndexPath, animated: false, scrollPosition: .none)

        deselectCurrentLayout()
        selectedLayout = GutenbergSelectedLayout(sectionSlug: slug, position: position)
    }

    func didDeselectItem(forCell cell: LayoutPickerSectionTableViewCell) {
        selectedLayout = nil
    }

    func accessibilityElementDidBecomeFocused(forCell cell: LayoutPickerSectionTableViewCell) {
        guard UIAccessibility.isVoiceOverRunning, let cellIndexPath = tableView.indexPath(for: cell) else { return }
        tableView.scrollToRow(at: cellIndexPath, at: .middle, animated: true)
    }

    private func deselectCurrentLayout() {
        guard let previousSelection = selectedLayout else { return }

        tableView.indexPathsForVisibleRows?.forEach { (indexPath) in
            if containsSelectedLayout(previousSelection, atIndexPath: indexPath) {
                (tableView.cellForRow(at: indexPath) as? LayoutPickerSectionTableViewCell)?.deselectItems()
            }
        }
    }
}

extension GutenbergLayoutPickerViewController: FilterBarDelegate {
    func numberOfFilters() -> Int {
        return sections.count
    }

    func filter(forIndex index: Int) -> GutenbergLayoutSection {
        return sections[index]
    }

    func didSelectFilter(withIndex selectedIndex: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath]) {
        guard filteredSections == nil else {
            insertFilterRow(withIndex: selectedIndex, withSelectedIndexes: selectedIndexes)
            return
        }

        let rowsToRemove = (0..<sections.count).compactMap { ($0 == selectedIndex.item) ? nil : IndexPath(row: $0, section: 0) }

        filteredSections = [sections[selectedIndex.item]]
        tableView.performBatchUpdates({
            tableView.deleteRows(at: rowsToRemove, with: .fade)
        }) { _ in
            self.snapToHeight(self.tableView, height: self.maxHeaderHeight)
        }
    }

    func insertFilterRow(withIndex selectedIndex: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath]) {

        var row: IndexPath? = nil
        let sortedIndexes = selectedIndexes.sorted(by: { $0.item < $1.item })
        for i in 0..<sortedIndexes.count {
            if sortedIndexes[i].item == selectedIndex.item {
                let indexPath = IndexPath(row: i, section: 0)
                filteredSections?.insert(sections[selectedIndex.item], at: i)
                row = indexPath
                break
            }
        }

        guard let rowToAdd = row else { return }
        tableView.performBatchUpdates({
            tableView.insertRows(at: [rowToAdd], with: .fade)
        })
    }

    func didDeselectFilter(withIndex index: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath]) {
        guard selectedIndexes.count == 0 else {
            removeFilterRow(withIndex: index)
            return
        }

        let currentRowSlug = filteredSections?.first?.section.slug
        filteredSections = nil
        let rowsToAdd = (0..<sections.count).compactMap { (sections[$0].section.slug == currentRowSlug) ? nil : IndexPath(row: $0, section: 0) }
        tableView.performBatchUpdates({
            tableView.insertRows(at: rowsToAdd, with: .fade)
        })
    }

    func removeFilterRow(withIndex index: IndexPath) {
        guard let filteredSections = filteredSections else { return }

        var row: IndexPath? = nil
        let rowSlug = sections[index.item].section.slug
        for i in 0..<filteredSections.count {
            if filteredSections[i].section.slug == rowSlug {
                let indexPath = IndexPath(row: i, section: 0)
                self.filteredSections?.remove(at: i)
                row = indexPath
                break
            }
        }

        guard let rowToRemove = row else { return }
        tableView.performBatchUpdates({
            tableView.deleteRows(at: [rowToRemove], with: .fade)
        }) { _ in
            if (self.filteredSections?.count ?? 0) < 2 {
                self.snapToHeight(self.tableView, height: self.maxHeaderHeight)
            }
        }
    }
}
