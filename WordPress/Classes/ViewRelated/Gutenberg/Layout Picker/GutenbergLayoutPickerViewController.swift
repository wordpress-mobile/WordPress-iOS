import UIKit
import Gridicons
import Gutenberg

class GutenbergLayoutSection: CategorySection {
    var section: PageTemplateCategory
    var layouts: [PageTemplateLayout]
    var scrollOffset: CGPoint
    
    var categorySlug: String { section.slug }
    var title: String? { section.desc }
    var thumbnails: [Thumbnail] {
        // TODO: pass device different modes
        layouts.map { Thumbnail(urlDesktop: $0.preview, urlTablet: $0.preview, urlMobile: $0.preview, slug: $0.slug) }
    }

    init(_ section: PageTemplateCategory) {
        let layouts = Array(section.layouts ?? []).sorted()
        self.section = section
        self.layouts = layouts
        self.scrollOffset = .zero
    }
}

class GutenbergLayoutPickerViewController: FilterableCategoriesViewController {
    private var filteredSections: [GutenbergLayoutSection]?
    private var sections: [GutenbergLayoutSection] = []
    internal var visibleSections: [CategorySection] { filteredSections ?? sections }
    lazy var resultsController: NSFetchedResultsController<PageTemplateCategory> = {
        let resultsController = PageLayoutService.resultsController(forBlog: blog, delegate: self)
        sections = makeSectionData(with: resultsController)
        return resultsController
    }()
    
    private var isLoading: Bool = true {
        didSet {
            if isLoading {
                tableView.startGhostAnimation(style: GhostCellStyle.muriel)
            } else {
                tableView.stopGhostAnimation()
            }
            
            loadingStateChanged(isLoading)
            tableView.reloadData()
        }
    }
    
    let completion: PageCoordinator.TemplateSelectionCompletion
    let blog: Blog
    
    init(blog: Blog, completion: @escaping PageCoordinator.TemplateSelectionCompletion) {
        self.blog = blog
        self.completion = completion
        
        super.init(
            mainTitle: NSLocalizedString("Choose a Layout", comment: "Title for the screen to pick a template for a page"),
            prompt: NSLocalizedString("Get started by choosing from a wide variety of pre-made page layouts. Or just start with a blank page.", comment: "Prompt for the screen to pick a template for a page"),
            primaryActionTitle: NSLocalizedString("Create Page", comment: "Title for button to make a page with the contents of the selected layout"),
            secondaryActionTitle: NSLocalizedString("Preview", comment: "Title for button to preview a selected layout"),
            defaultActionTitle: NSLocalizedString("Create Blank Page", comment: "Title for button to make a blank page")
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(CategorySectionTableViewCell.nib, forCellReuseIdentifier: CategorySectionTableViewCell.cellReuseIdentifier)
        filterBar.filterDelegate = self
        tableView.dataSource = self
        fetchLayouts()
        configureCloseButton()
        navigationItem.backButtonTitle = NSLocalizedString("Choose layout", comment: "Shortened version of the main title to be used in back navigation")
    }
    
    private func configureCloseButton() {
        navigationItem.rightBarButtonItem = CollapsableHeaderViewController.closeButton(target: self, action: #selector(closeButtonTapped))
    }
    
    @objc func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    private func presentPreview() {
        guard let sectionIndex = selectedItem?.section, let position = selectedItem?.item else { return }
        let layout = sections[sectionIndex].layouts[position]
        let destination = LayoutPreviewViewController(layout: layout, completion: completion)
        LayoutPickerAnalyticsEvent.templatePreview(slug: layout.slug)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    private func createPage(layout: PageTemplateLayout?) {
        dismiss(animated: true) {
            self.completion(layout)
        }
    }
    
    private func fetchLayouts() {
        isLoading = resultsController.isEmpty()
        let expectedThumbnailSize = CategorySectionTableViewCell.expectedThumbnailSize
        PageLayoutService.fetchLayouts(forBlog: blog, withThumbnailSize: expectedThumbnailSize) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismissNoResultsController()
                case .failure(let error):
                    self?.handleErrors(error)
                }
            }
        }
    }
    
    private func handleErrors(_ error: Error) {
        guard resultsController.isEmpty() else { return }
        isLoading = false
        let titleText = NSLocalizedString("Unable to load this content right now.", comment: "Informing the user that a network request failed becuase the device wasn't able to establish a network connection.")
        let subtitleText = NSLocalizedString("Check your network connection and try again or create a blank page.", comment: "Default subtitle for no-results when there is no connection with a prompt to create a new page instead.")
        displayNoResultsController(title: titleText, subtitle: subtitleText, resultsDelegate: self)
    }
    
    private func makeSectionData(with controller: NSFetchedResultsController<PageTemplateCategory>?) -> [GutenbergLayoutSection] {
        return controller?.fetchedObjects?.map({ (category) -> GutenbergLayoutSection in
            return GutenbergLayoutSection(category)
        }) ?? []
    }
    
    override func estimatedContentSize() -> CGSize {
        let rowCount = CGFloat(max(visibleSections.count, 1))
        let estimatedRowHeight: CGFloat = CategorySectionTableViewCell.estimatedCellHeight
        let estimatedHeight = (estimatedRowHeight * rowCount)
        return CGSize(width: tableView.contentSize.width, height: estimatedHeight)
    }
    
    // MARK: - Footer Actions
    override func defaultActionSelected(_ sender: Any) {
        createPage(layout: nil)
    }
    
    override func primaryActionSelected(_ sender: Any) {
        guard let sectionIndex = selectedItem?.section, let position = selectedItem?.item else {
            createPage(layout: nil)
            return
        }
        
        let layout = sections[sectionIndex].layouts[position]
        LayoutPickerAnalyticsEvent.templateApplied(slug: layout.slug)
        createPage(layout: layout)
    }
    
    override func secondaryActionSelected(_ sender: Any) {
        presentPreview()
    }
    
    public func loadingStateChanged(_ isLoading: Bool) {
        filterBar.shouldShowGhostContent = isLoading
        filterBar.allowsMultipleSelection = !isLoading
        filterBar.reloadData()
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CategorySectionTableViewCell.estimatedCellHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isLoading ? 1 : (visibleSections.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellReuseIdentifier = CategorySectionTableViewCell.cellReuseIdentifier
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? CategorySectionTableViewCell else {
            fatalError("Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(CategorySectionTableViewCell.self). Please make sure the table view is registering the correct nib before loading the data")
        }
        cell.delegate = self
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.section = isLoading ? nil : visibleSections[indexPath.row]
        cell.isGhostCell = isLoading
        cell.layer.masksToBounds = false
        cell.clipsToBounds = false
        cell.collectionView.allowsSelection = !isLoading
        if let selectedItem = selectedItem, containsSelectedItem(selectedItem, atIndexPath: indexPath) {
            cell.selectItemAt(selectedItem.item)
        }
        
        return cell
    }
    
    private func containsSelectedItem(_ selectedIndexPath: IndexPath, atIndexPath indexPath: IndexPath) -> Bool {
        let sectionSlug = sections[selectedIndexPath.section].section.slug
        let rowSection = visibleSections[indexPath.row]
        return (sectionSlug == rowSection.categorySlug)
    }
}

extension GutenbergLayoutPickerViewController: CategorySectionTableViewCellDelegate {
    
    func didSelectItemAt(_ position: Int, forCell cell: CategorySectionTableViewCell, slug: String) {
        guard let cellIndexPath = tableView.indexPath(for: cell),
              let sectionIndex = sections.firstIndex(where: { $0.section.slug == slug })
        else { return }
        
        tableView.selectRow(at: cellIndexPath, animated: false, scrollPosition: .none)
        deselectCurrentLayout()
        selectedItem = IndexPath(item: position, section: sectionIndex)
    }
    
    func didDeselectItem(forCell cell: CategorySectionTableViewCell) {
        selectedItem = nil
    }
    
    func accessibilityElementDidBecomeFocused(forCell cell: CategorySectionTableViewCell) {
        guard UIAccessibility.isVoiceOverRunning, let cellIndexPath = tableView.indexPath(for: cell) else { return }
        tableView.scrollToRow(at: cellIndexPath, at: .middle, animated: true)
    }
    
    private func deselectCurrentLayout() {
        guard let previousSelection = selectedItem else { return }
        
        tableView.indexPathsForVisibleRows?.forEach { (indexPath) in
            if containsSelectedItem(previousSelection, atIndexPath: indexPath) {
                (tableView.cellForRow(at: indexPath) as? CategorySectionTableViewCell)?.deselectItems()
            }
        }
    }
}

extension GutenbergLayoutPickerViewController: CollapsableHeaderFilterBarDelegate {
    func numberOfFilters() -> Int {
        return sections.count
    }
    
    func filter(forIndex index: Int) -> CollabsableHeaderFilterOption {
        return sections[index].section
    }
    
    func didSelectFilter(withIndex selectedIndex: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath]) {
        guard filteredSections == nil else {
            insertFilterRow(withIndex: selectedIndex, withSelectedIndexes: selectedIndexes)
            return
        }
        
        let rowsToRemove = (0..<sections.count).compactMap { ($0 == selectedIndex.item) ? nil : IndexPath(row: $0, section: 0) }
        
        filteredSections = [sections[selectedIndex.item]]
        tableView.performBatchUpdates({
            contentSizeWillChange()
            tableView.deleteRows(at: rowsToRemove, with: .fade)
        })
    }
    
    func insertFilterRow(withIndex selectedIndex: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath]) {
        let sortedIndexes = selectedIndexes.sorted(by: { $0.item < $1.item })
        for i in 0..<sortedIndexes.count {
            if sortedIndexes[i].item == selectedIndex.item {
                filteredSections?.insert(sections[selectedIndex.item], at: i)
                break
            }
        }
        
        tableView.performBatchUpdates({
            if selectedIndexes.count == 2 {
                contentSizeWillChange()
            }
            tableView.reloadSections([0], with: .automatic)
        })
    }
    
    func didDeselectFilter(withIndex index: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath]) {
        guard selectedIndexes.count == 0 else {
            removeFilterRow(withIndex: index)
            return
        }
        
        filteredSections = nil
        tableView.performBatchUpdates({
            contentSizeWillChange()
            tableView.reloadSections([0], with: .fade)
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
            contentSizeWillChange()
            tableView.deleteRows(at: [rowToRemove], with: .fade)
        })
    }
}

extension GutenbergLayoutPickerViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = makeSectionData(with: resultsController)
        isLoading = resultsController.isEmpty()
        contentSizeWillChange()
        tableView.reloadData()
    }
}

extension GutenbergLayoutPickerViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        fetchLayouts()
    }
}
