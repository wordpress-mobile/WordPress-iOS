import WordPressUI

class ReaderTagCardCell: UITableViewCell {

    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewHeightConstraint: NSLayoutConstraint!

    // A 'fake' collection view that's displayed over the actual collection view.
    // This view will be displaying the loading animation while the cell is in loading state.
    //
    // We can't call our ghost functions on the actual collection view because it uses a
    // diffable data source, which cannot be "hot-swapped".
    // See: https://developer.apple.com/documentation/uikit/uicollectionviewdiffabledatasource
    private lazy var ghostableCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.clipsToBounds = false

        let cellNibName = ReaderTagCell.classNameWithoutNamespaces()
        let nib = UINib(nibName: cellNibName, bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellNibName)

        return collectionView
    }()

    private var viewModel: ReaderTagCardCellViewModel?

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

    override func awakeFromNib() {
        super.awakeFromNib()
        registerCells()
        setupButtonStyles()
        accessibilityElements = [tagButton, collectionView].compactMap { $0 }
        collectionViewHeightConstraint.constant = cellSize.height

        // disable ghost animation on the actual collection view to prevent its data source and delegate
        // from being overridden.
        collectionView?.isGhostableDisabled = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        collectionViewHeightConstraint.constant = cellSize.height
        hideGhostLoading() // clean up attached ghost views, if any
    }

    func configure(parent: UIViewController, tag: ReaderTagTopic, isLoggedIn: Bool, shouldSyncRemotely: Bool = false) {
        if viewModel?.slug == tag.slug {
            return
        }
        resetScrollPosition()
        weak var weakSelf = self
        viewModel = ReaderTagCardCellViewModel(parent: parent,
                                               tag: tag,
                                               collectionView: collectionView,
                                               isLoggedIn: isLoggedIn,
                                               viewDelegate: self,
                                               cellSize: weakSelf?.cellSize)
        viewModel?.fetchTagPosts(syncRemotely: shouldSyncRemotely)
        tagButton.setTitle(tag.title, for: .normal)
    }

    @IBAction private func onTagButtonTapped(_ sender: Any) {
        viewModel?.onTagButtonTapped(source: .header)
    }

    struct Constants {
        static let phoneDefaultCellSize = CGSize(width: 300, height: 150)
        static let phoneLargeCellSize = CGSize(width: 300, height: 300)
        static let padDefaultCellSize = CGSize(width: 480, height: 206)
        static let padLargeCellSize = CGSize(width: 480, height: 400)
    }

}

// MARK: - ReaderTagCardCellViewModelDelegate

extension ReaderTagCardCell: ReaderTagCardCellViewModelDelegate {
    func showLoading() {
        showGhostLoading()
    }

    func hideLoading() {
        hideGhostLoading()
    }
}

// MARK: - Private methods

private extension ReaderTagCardCell {

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

    func registerCells() {
        let tagCell = UINib(nibName: ReaderTagCell.classNameWithoutNamespaces(), bundle: nil)
        let footerView = UINib(nibName: ReaderTagFooterView.classNameWithoutNamespaces(), bundle: nil)
        collectionView.register(ReaderTagCardEmptyCell.self, forCellWithReuseIdentifier: ReaderTagCardEmptyCell.defaultReuseID)
        collectionView.register(tagCell, forCellWithReuseIdentifier: ReaderTagCell.classNameWithoutNamespaces())
        collectionView.register(footerView,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: ReaderTagFooterView.classNameWithoutNamespaces())
    }

    /// Injects a "fake" UICollectionView for the loading state animation.
    func showGhostLoading() {
        guard let collectionView,
              let containerView = collectionView.superview,
              ghostableCollectionView.superview == nil else {
            return
        }

        // setup the 'fake' collection view.
        containerView.addSubview(ghostableCollectionView)

        // pin it directly over the current collection view.
        NSLayoutConstraint.activate([
            ghostableCollectionView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            ghostableCollectionView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            ghostableCollectionView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            ghostableCollectionView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])

        // Important: since the size are fixed, we want to make sure that we feed the exact item size
        // so that it perfectly overlays on top of the "actual" collection view.
        if let flowLayout = ghostableCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = cellSize
        }

        let options = GhostOptions(reuseIdentifier: ReaderTagCell.classNameWithoutNamespaces(), rowsPerSection: [3])
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)

        ghostableCollectionView.removeGhostContent()
        ghostableCollectionView.displayGhostContent(options: options, style: style)
        ghostableCollectionView.isScrollEnabled = false
    }

    func hideGhostLoading() {
        // ensure that the ghostable collection view is present in the view hierarchy.
        guard ghostableCollectionView.superview != nil else {
            return
        }

        ghostableCollectionView.removeGhostContent()
        ghostableCollectionView.removeFromSuperview()
    }

    func resetScrollPosition() {
        let isRTL = UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft
        if isRTL {
            collectionView.scrollToEnd(animated: false)
        } else {
            collectionView.scrollToStart(animated: false)
        }
    }
}

private extension UIScrollView {
    func scrollToEnd(animated: Bool) {
        let endOffset = CGPoint(x: contentSize.width - bounds.size.width, y: 0)
        if endOffset.x > 0 {
            setContentOffset(endOffset, animated: animated)
            layoutIfNeeded()
        }
    }

    func scrollToStart(animated: Bool) {
        let startOffset = CGPoint(x: 0, y: 0)
        setContentOffset(startOffset, animated: animated)
        layoutIfNeeded()
    }
}
