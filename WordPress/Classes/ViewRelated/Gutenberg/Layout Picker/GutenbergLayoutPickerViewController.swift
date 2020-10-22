import UIKit
import Gridicons
import Gutenberg

class GutenbergLayoutSection {
    var section: PageTemplateCategory
    var layouts: [PageTemplateLayout]
    var scrollOffset: CGPoint

    init(_ section: PageTemplateCategory) {
        let layouts = Array(section.layouts ?? []).sorted()
        self.section = section
        self.layouts = layouts
        self.scrollOffset = .zero
    }
}

class GutenbergLayoutPickerViewController: UIViewController, CollapsableHeaderDataSource, CollapsableHeaderDelegate {
    let defaultActionTitle = NSLocalizedString("Create Blank Page", comment: "Title for button to make a blank page")
    let primaryActionTitle = NSLocalizedString("Create Page", comment: "Title for button to make a page with the contents of the selected layout")
    let secondaryActionTitle = NSLocalizedString("Preview", comment: "Title for button to preview a selected layout")
    let mainTitle = NSLocalizedString("Choose a Layout", comment: "Title for the screen to pick a template for a page")
    let prompt = NSLocalizedString("Get started by choosing from a wide variety of pre-made page layouts. Or just start with a blank page.", comment: "Prompt for the screen to pick a template for a page")
    weak var headerContentsDelegate: CollapsableHeaderContentsDelegate?

    @IBOutlet weak var tableView: UITableView!
    var scrollView: UIScrollView {
        return tableView
    }

    private var selectedLayout: IndexPath? = nil {
        didSet {
            if !(oldValue != nil && selectedLayout != nil) {
                headerContentsDelegate?.itemSelectionChanged(selectedLayout != nil)
            }
        }
    }

    private var filteredSections: [GutenbergLayoutSection]?
    private var sections: [GutenbergLayoutSection] = []
    var resultsController: NSFetchedResultsController<PageTemplateCategory>? {
        didSet {
            sections = makeSectionData(with: resultsController)
        }
    }

    private var isLoading: Bool = true {
        didSet {
            if isLoading {
                tableView.startGhostAnimation(style: GhostCellStyle.muriel)
            } else {
                tableView.stopGhostAnimation()
            }

            headerContentsDelegate?.loadingStateChanged(isLoading)
            tableView.reloadData()
        }
    }

    var completion: PageCoordinator.TemplateSelectionCompletion? = nil
    var blog: Blog? = nil {
        didSet {
            if let blog = blog {
                resultsController = PageLayoutService.resultsController(forBlog: blog, delegate: self)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(LayoutPickerSectionTableViewCell.nib, forCellReuseIdentifier: LayoutPickerSectionTableViewCell.cellReuseIdentifier)
        fetchLayouts()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.isNavigationBarHidden = false

        if let destination = segue.destination as? LayoutPreviewViewController,
           let sectionIndex = selectedLayout?.section,
           let position = selectedLayout?.item {
            let layout = sections[sectionIndex].layouts[position]
            LayoutPickerAnalyticsEvent.templatePreview(slug: layout.slug)
            destination.layout = layout
            destination.completion = completion
        }

        super.prepare(for: segue, sender: sender)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let previousTraitCollection = previousTraitCollection, traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass {
            if let visibleRow = tableView.indexPathsForVisibleRows?.first {
                tableView.scrollToRow(at: visibleRow, at: .top, animated: true)
            }
        }
    }

    private func createPage(layout: PageTemplateLayout?) {
        guard let completion = completion else {
            dismiss(animated: true, completion: nil)
            return
        }

        dismiss(animated: true) {
            completion(layout)
        }
    }

    private func fetchLayouts() {
        guard let blog = blog else { return }
        isLoading = resultsController?.isEmpty() ?? true
        let expectedThumbnailSize = LayoutPickerSectionTableViewCell.expectedTumbnailSize
        PageLayoutService.layouts(forBlog: blog, withThumbnailSize: expectedThumbnailSize) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.headerContentsDelegate?.dismissNoResultsController()
                case .failure(let error):
                    self?.handleErrors(error)
                }
            }
        }
    }

    private func handleErrors(_ error: Error) {
        guard resultsController?.isEmpty() ?? true else { return }
        isLoading = false
        let titleText = NSLocalizedString("Unable to load this content right now.", comment: "Informing the user that a network request failed becuase the device wasn't able to establish a network connection.")
        let subtitleText = NSLocalizedString("Check your network connection and try again or create a blank page.", comment: "Default subtitle for no-results when there is no connection with a prompt to create a new page instead.")
        headerContentsDelegate?.displayNoResultsController(title: titleText, subtitle: subtitleText, resultsDelegate: self)
    }

    private func makeSectionData(with controller: NSFetchedResultsController<PageTemplateCategory>?) -> [GutenbergLayoutSection] {
        return controller?.fetchedObjects?.map({ (category) -> GutenbergLayoutSection in
            return GutenbergLayoutSection(category)
        }) ?? []
    }

    func defaultActionSelected() {
        createPage(layout: nil)
    }

    func primaryActionSelected() {
        guard let sectionIndex = selectedLayout?.section, let position = selectedLayout?.item else {
            createPage(layout: nil)
            return
        }

        let layout = sections[sectionIndex].layouts[position]
        LayoutPickerAnalyticsEvent.templateApplied(slug: layout.slug)
        createPage(layout: layout)
    }

    func secondaryActionSelected() {
        performSegue(withIdentifier: "preview", sender: nil)
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return LayoutPickerSectionTableViewCell.estimatedCellHeight
    }

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
            cell.selectItemAt(selectedLayout.item)
        }

        return cell
    }

    private func containsSelectedLayout(_ selectedIndexPath: IndexPath, atIndexPath indexPath: IndexPath) -> Bool {
        let rowSection = (filteredSections ?? sections)[indexPath.row]
        let sectionSlug = sections[selectedIndexPath.section].section.slug
        return (sectionSlug == rowSection.section.slug)
    }

    func estimatedContentSize() -> CGSize {
        let rowCount = CGFloat(max((filteredSections ?? sections).count, 1))
        let estimatedRowHeight: CGFloat = LayoutPickerSectionTableViewCell.estimatedCellHeight
        let estimatedHeight = (estimatedRowHeight * rowCount)
        return CGSize(width: tableView.contentSize.width, height: estimatedHeight)
    }
}

extension GutenbergLayoutPickerViewController: LayoutPickerSectionTableViewCellDelegate {

    func didSelectLayoutAt(_ position: Int, forCell cell: LayoutPickerSectionTableViewCell) {
        guard let cellIndexPath = tableView.indexPath(for: cell),
              let slug = cell.section?.section.slug,
              let sectionIndex = sections.firstIndex(where: { $0.section.slug == slug })
        else { return }

        tableView.selectRow(at: cellIndexPath, animated: false, scrollPosition: .none)
        deselectCurrentLayout()
        selectedLayout = IndexPath(item: position, section: sectionIndex)
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
            headerContentsDelegate?.contentSizeWillChange()
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
                headerContentsDelegate?.contentSizeWillChange()
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
            headerContentsDelegate?.contentSizeWillChange()
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
            headerContentsDelegate?.contentSizeWillChange()
            tableView.deleteRows(at: [rowToRemove], with: .fade)
        })
    }
}

extension GutenbergLayoutPickerViewController: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = makeSectionData(with: resultsController)
        isLoading = resultsController?.isEmpty() ?? true
        headerContentsDelegate?.contentSizeWillChange()
        tableView.reloadData()
    }
}

extension GutenbergLayoutPickerViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        fetchLayouts()
    }
}
