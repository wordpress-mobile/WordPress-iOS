class ReaderTagCardCell: UITableViewCell {

    @IBOutlet private weak var tagButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewHeightConstraint: NSLayoutConstraint!

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
        registerTagCell()
        setupButtonStyles()
        accessibilityElements = [tagButton, collectionView].compactMap { $0 }
        collectionViewHeightConstraint.constant = cellSize.height
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        collectionViewHeightConstraint.constant = cellSize.height
    }

    func configure(parent: UIViewController, tag: ReaderTagTopic, isLoggedIn: Bool, shouldSyncRemotely: Bool = false) {
        weak var weakSelf = self
        viewModel = ReaderTagCardCellViewModel(parent: parent,
                                               tag: tag,
                                               collectionView: collectionView,
                                               isLoggedIn: isLoggedIn,
                                               cellSize: weakSelf?.cellSize)
        viewModel?.fetchTagPosts(syncRemotely: shouldSyncRemotely)
        tagButton.setTitle(tag.title, for: .normal)
    }

    @IBAction private func onTagButtonTapped(_ sender: Any) {
        viewModel?.onTagButtonTapped()
    }

    struct Constants {
        static let phoneDefaultCellSize = CGSize(width: 240, height: 297)
        static let phoneLargeCellSize = CGSize(width: 240, height: 500)
        static let padDefaultCellSize = CGSize(width: 480, height: 600)
        static let padLargeCellSize = CGSize(width: 480, height: 900)
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

    func registerTagCell() {
        let nib = UINib(nibName: ReaderTagCell.classNameWithoutNamespaces(), bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: ReaderTagCell.classNameWithoutNamespaces())
    }

}
