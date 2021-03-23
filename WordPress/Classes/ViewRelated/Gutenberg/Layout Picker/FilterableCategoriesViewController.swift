import UIKit
import Gridicons
import Gutenberg

class FilterableCategoriesViewController: CollapsableHeaderViewController {
    private enum CategoryFilterAnalyticsKeys {
        static let modifiedFilter = "filter"
        static let selectedFilters = "selected_filters"
        static let location = "location"
    }

    typealias PreviewDevice = PreviewDeviceSelectionViewController.PreviewDevice
    let tableView: UITableView
    private lazy var debounceSelectionChange: Debouncer = {
        Debouncer(delay: 0.1) { [weak self] in
            guard let `self` = self else { return }
            self.itemSelectionChanged(self.selectedItem != nil)
        }
    }()
    internal var selectedItem: IndexPath? = nil {
        didSet {
            debounceSelectionChange.call()
        }
    }
    private let filterBar: CollapsableHeaderFilterBar

    internal var categorySections: [CategorySection] { get {
        fatalError("This should be overridden by the subclass to provide a conforming collection of categories")
    } }

    private var filteredSections: [CategorySection]?
    private var visibleSections: [CategorySection] { filteredSections ?? categorySections }

    internal var isLoading: Bool = true {
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

    var selectedPreviewDevice = PreviewDevice.default {
        didSet {
            tableView.reloadData()
        }
    }

    let analyticsLocation: String
    init(
        analyticsLocation: String,
        mainTitle: String,
        prompt: String,
        primaryActionTitle: String,
        secondaryActionTitle: String? = nil,
        defaultActionTitle: String? = nil
    ) {
        self.analyticsLocation = analyticsLocation
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.showsVerticalScrollIndicator = false
        filterBar = CollapsableHeaderFilterBar()
        super.init(scrollableView: tableView,
                   mainTitle: mainTitle,
                   prompt: prompt,
                   primaryActionTitle: primaryActionTitle,
                   secondaryActionTitle: secondaryActionTitle,
                   defaultActionTitle: defaultActionTitle,
                   accessoryView: filterBar)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(CategorySectionTableViewCell.nib, forCellReuseIdentifier: CategorySectionTableViewCell.cellReuseIdentifier)
        filterBar.filterDelegate = self
        tableView.dataSource = self
        configureCloseButton()
    }

    private func configureCloseButton() {
        navigationItem.rightBarButtonItem = CollapsableHeaderViewController.closeButton(target: self, action: #selector(closeButtonTapped))
    }

    @objc func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    override func estimatedContentSize() -> CGSize {
        let rowCount = CGFloat(max(visibleSections.count, 1))
        let estimatedRowHeight: CGFloat = CategorySectionTableViewCell.estimatedCellHeight
        let estimatedHeight = (estimatedRowHeight * rowCount)
        return CGSize(width: tableView.contentSize.width, height: estimatedHeight)
    }

    public func loadingStateChanged(_ isLoading: Bool) {
        filterBar.shouldShowGhostContent = isLoading
        filterBar.allowsMultipleSelection = !isLoading
        filterBar.reloadData()
    }
}

extension FilterableCategoriesViewController: UITableViewDataSource {

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
        let rowSection = visibleSections[indexPath.row]
        let sectionSlug = categorySections[selectedIndexPath.section].categorySlug
        return (sectionSlug == rowSection.categorySlug)
    }
}

extension FilterableCategoriesViewController: CategorySectionTableViewCellDelegate {
    func didSelectItemAt(_ position: Int, forCell cell: CategorySectionTableViewCell, slug: String) {
        guard let cellIndexPath = tableView.indexPath(for: cell),
              let sectionIndex = categorySections.firstIndex(where: { $0.categorySlug == slug })
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

extension FilterableCategoriesViewController: CollapsableHeaderFilterBarDelegate {
    func numberOfFilters() -> Int {
        return categorySections.count
    }

    func filter(forIndex index: Int) -> CategorySection {
        return categorySections[index]
    }

    func didSelectFilter(withIndex selectedIndex: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath]) {
        trackFiltersChangedEvent(isSelectionEvent: true, changedIndex: selectedIndex, selectedIndexes: selectedIndexes)
        guard filteredSections == nil else {
            insertFilterRow(withIndex: selectedIndex, withSelectedIndexes: selectedIndexes)
            return
        }

        let rowsToRemove = (0..<categorySections.count).compactMap { ($0 == selectedIndex.item) ? nil : IndexPath(row: $0, section: 0) }

        filteredSections = [categorySections[selectedIndex.item]]
        tableView.performBatchUpdates({
            contentSizeWillChange()
            tableView.deleteRows(at: rowsToRemove, with: .fade)
        })
    }

    func insertFilterRow(withIndex selectedIndex: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath]) {
        let sortedIndexes = selectedIndexes.sorted(by: { $0.item < $1.item })
        for i in 0..<sortedIndexes.count {
            if sortedIndexes[i].item == selectedIndex.item {
                filteredSections?.insert(categorySections[selectedIndex.item], at: i)
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
        trackFiltersChangedEvent(isSelectionEvent: false, changedIndex: index, selectedIndexes: selectedIndexes)
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

    func trackFiltersChangedEvent(isSelectionEvent: Bool, changedIndex: IndexPath, selectedIndexes: [IndexPath]) {
        let event: WPAnalyticsEvent = isSelectionEvent ? .categoryFilterSelected : .categoryFilterDeselected
        let filter = categorySections[changedIndex.item].categorySlug
        let selectedFilters = selectedIndexes.map({ categorySections[$0.item].categorySlug }).joined(separator: ", ")

        WPAnalytics.track(event, properties: [
            CategoryFilterAnalyticsKeys.location: analyticsLocation,
            CategoryFilterAnalyticsKeys.modifiedFilter: filter,
            CategoryFilterAnalyticsKeys.selectedFilters: selectedFilters
        ])
    }

    func removeFilterRow(withIndex index: IndexPath) {
        guard let filteredSections = filteredSections else { return }

        var row: IndexPath? = nil
        let rowSlug = categorySections[index.item].categorySlug
        for i in 0..<filteredSections.count {
            if filteredSections[i].categorySlug == rowSlug {
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
