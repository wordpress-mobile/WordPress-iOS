import UIKit

class ThemeSelectionViewController: UICollectionViewController, LoginWithLogoAndHelpViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties

    var siteType: SiteType!
    private typealias Styles = WPStyleGuide.Themes

    private let themeService = ThemeService(managedObjectContext: ContextManager.sharedInstance().mainContext)

    private lazy var themesController: NSFetchedResultsController<NSFetchRequestResult> = {
        return self.createThemesFetchedResultsController()
    }()

    private var themeCount: NSInteger {
        return themesController.fetchedObjects?.count ?? 0
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        fetchThemes()
    }

    private func configureView() {
        WPStyleGuide.configureColors(for: view, collectionView: collectionView)
        _ = addHelpButtonToNavController()
        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ThemeSelectionHeaderView.reuseIdentifier, for: indexPath) as! ThemeSelectionHeaderView
        }
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themeCount
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectThemeCell.reuseIdentifier, for: indexPath) as! SelectThemeCell
        cell.displayTheme = themeAtIndexPath(indexPath)
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return Styles.cellSizeForFrameWidth(collectionView.frame.size.width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Styles.themeMargins
    }

    // MARK: - Theme Fetching

    private func createThemesFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Theme.entityName())
        fetchRequest.fetchBatchSize = 4
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: self.themeService.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self

        return frc
    }

    private func fetchThemes() {
        do {
            themesController.fetchRequest.predicate = themesPredicate()
            try themesController.performFetch()
        } catch {
            DDLogError("Error fetching themes: \(error)")
        }
    }

    private func themesPredicate() -> NSPredicate? {
        let blogThemes = ["Independent Publisher 2", "Penscratch 2", "Intergalactic 2", "Libre 2"]
        let websiteThemes = ["Radcliffe 2", "Karuna", "Dara", "Twenty Seventeen"]
        let portfolioThemes = ["Altofocus", "Rebalance", "Sketch", "Lodestar"]

        var themes: [String]
        switch siteType {
        case .blog: themes = blogThemes
        case .website: themes = websiteThemes
        case .portfolio: themes = portfolioThemes
        case .none:
            return nil
        case .some(_):
            return nil
        }

        var predicates = [NSPredicate]()
        for themeName in themes {
            predicates.append(NSPredicate(format: "name = %@", themeName))
        }

        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }

    // MARK: - Helpers

    private func themeAtIndexPath(_ indexPath: IndexPath) -> Theme? {
        return themesController.object(at: IndexPath(row: indexPath.row, section: 0)) as? Theme
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
