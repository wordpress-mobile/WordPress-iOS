class ReaderTagCardCell: UITableViewCell, UICollectionViewDelegate {

    private typealias DataSource = UICollectionViewDiffableDataSource<Int, NSManagedObjectID>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!

    private lazy var dataSource: DataSource = {
        DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, objectID in
            guard let post = try? ContextManager.shared.mainContext.existingObject(with: objectID) as? ReaderPost,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellIdentifier, for: indexPath) as? ReaderTagCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: post, isLoggedIn: self?.isLoggedIn ?? AccountHelper.isLoggedIn)
            return cell
        }
    }()
    private lazy var resultsController: NSFetchedResultsController<ReaderPost> = {
        let fetchRequest = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortRank", ascending: true)]
        fetchRequest.fetchLimit = Constants.displayPostLimit
        let resultsController = NSFetchedResultsController<ReaderPost>(fetchRequest: fetchRequest,
                                                           managedObjectContext: ContextManager.shared.mainContext,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)
        resultsController.delegate = self
        return resultsController
    }()
    private var isLoggedIn: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        registerTagCell()
        setupButtonStyles()
        collectionView.delegate = self
        accessibilityElements = [tagButton, collectionView].compactMap { $0 }
        collectionViewHeightConstraint.constant = cellSize.height
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        collectionViewHeightConstraint.constant = cellSize.height
    }

    func configure(with tag: ReaderTagTopic, isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
        tagButton.setTitle(tag.title, for: .normal)
        resultsController.fetchRequest.predicate = NSPredicate(format: "topic = %@ AND isSiteBlocked = NO", tag)
        try? resultsController.performFetch()
    }
}

// MARK: - Private methods

private extension ReaderTagCardCell {

    var cellSize: CGSize {
        let isAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let isPad = traitCollection.userInterfaceIdiom == .pad

        switch (isAccessibilityCategory, isPad) {
        case (true, true):
            return Constants.padLargeCellSize
        case (false, true):
            return Constants.padDefaultCellSize
        case (true, false):
            return Constants.phoneLargeCellSize
        case (false, false):
            return Constants.phoneDefaultCellSize
        }
    }

    func setupButtonStyles() {
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.cornerStyle = .capsule
        buttonConfig.baseForegroundColor = .label
        buttonConfig.baseBackgroundColor = UIColor(light: .secondarySystemBackground,
                                                   dark: .tertiarySystemBackground)
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        let font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        buttonConfig.titleTextAttributesTransformer = .transformer(with: font)
        tagButton.configuration = buttonConfig
    }

    func registerTagCell() {
        let nib = UINib(nibName: ReaderTagCell.classNameWithoutNamespaces(), bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: Constants.cellIdentifier)
    }

    struct Constants {
        static let cellIdentifier = ReaderTagCell.classNameWithoutNamespaces()
        static let displayPostLimit = 10
        static let phoneDefaultCellSize = CGSize(width: 240, height: 297)
        static let phoneLargeCellSize = CGSize(width: 240, height: 500)
        static let padDefaultCellSize = CGSize(width: 480, height: 600)
        static let padLargeCellSize = CGSize(width: 480, height: 900)
    }

}

// MARK: - NSFetchedResultsControllerDelegate

extension ReaderTagCardCell: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        dataSource.apply(snapshot as Snapshot, animatingDifferences: false)
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension ReaderTagCardCell: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }

}
