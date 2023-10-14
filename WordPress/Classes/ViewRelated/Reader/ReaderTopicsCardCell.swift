import UIKit

/// A cell that displays topics the user might like
///
class ReaderTopicsCardCell: UITableViewCell, NibLoadable {
    // Views
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    private let layout = ReaderTagsCollectionViewLayout()

    private(set) var data: [ReaderAbstractTopic] = [] {
        didSet {
            guard oldValue != data else {
                return
            }
            refreshData()
        }
    }

    weak var delegate: ReaderTopicsTableCardCellDelegate?

    static var defaultNibName: String {
        RemoteFeatureFlag.readerImprovements.enabled() ? "ReaderTopicsNewCardCell" : String(describing: self)
    }

    func configure(_ data: [ReaderAbstractTopic]) {
        self.data = data
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()

        // Configure header
        headerLabel.text = Constants.title

        // Configure collection view
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ReaderInterestsCollectionViewCell.defaultNib,
                                forCellWithReuseIdentifier: ReaderInterestsCollectionViewCell.defaultReuseID)
        collectionView.register(ReaderTopicCardCollectionViewCell.self,
                                forCellWithReuseIdentifier: ReaderTopicCardCollectionViewCell.cellReuseIdentifier())

        if RemoteFeatureFlag.readerImprovements.enabled() {
            configureForNewDesign()
        }
    }

    private func applyStyles() {
        let usesNewDesign = RemoteFeatureFlag.readerImprovements.enabled()
        headerLabel.font = usesNewDesign ? WPStyleGuide.fontForTextStyle(.footnote) : WPStyleGuide.serifFontForTextStyle(.title2)

        containerView.backgroundColor = usesNewDesign ? .secondarySystemBackground : .listForeground
        headerLabel.backgroundColor = usesNewDesign ? .secondarySystemBackground : .listForeground
        collectionView.backgroundColor = usesNewDesign ? .secondarySystemBackground : .listForeground

        backgroundColor = .clear
        contentView.backgroundColor = usesNewDesign ? .systemBackground : .listForeground
    }


    /// Configures the cell and the collection view for the new design.
    private func configureForNewDesign() {
        // set up custom collection view flow layout
        layout.interitemSpacing = 8.0
        layout.lineSpacing = 8.0
        layout.delegate = self
        collectionView.collectionViewLayout = layout

        // header title color
        headerLabel.textColor = .secondaryLabel

        // corner radius
        containerView.layer.cornerRadius = 10.0

        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground

        // add manual separator view
        let separatorView = UIView()
        separatorView.backgroundColor = .separator
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func refreshData() {
        collectionView.reloadData()
    }

    private struct Constants {
        static let title = NSLocalizedString("You might like", comment: "A suggestion of topics the user might like")

        static let reuseIdentifier = ReaderInterestsCollectionViewCell.defaultReuseID

        static let collectionViewMinHeight: CGFloat = 40.0
    }
}

// MARK: - Collection View: Datasource & Delegate
extension ReaderTopicsCardCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if RemoteFeatureFlag.readerImprovements.enabled() {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReaderTopicCardCollectionViewCell.cellReuseIdentifier(), for: indexPath) as? ReaderTopicCardCollectionViewCell else {
                return UICollectionViewCell()
            }

            let title = data[indexPath.row].title
            cell.titleLabel.text = title

            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.reuseIdentifier,
                                                            for: indexPath) as? ReaderInterestsCollectionViewCell else {
            fatalError("Expected a ReaderInterestsCollectionViewCell for identifier: \(Constants.reuseIdentifier)")
        }

        let title = data[indexPath.row].title

        ReaderSuggestedTopicsStyleGuide.applySuggestedTopicStyle(label: cell.label,
                                                                 with: indexPath.row)

        cell.label.text = title
        cell.label.accessibilityIdentifier = .topicsCardCellIdentifier
        cell.label.accessibilityTraits = .button

        // We need to use the calculated size for the height / corner radius because the cell size doesn't change until later
        let size = sizeForCell(title: title)
        cell.label.layer.cornerRadius = size.height * 0.5

        return cell
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            refreshData()
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let topic = data[indexPath.row]

        delegate?.didSelect(topic: topic)
    }
}

// MARK: - Collection View: Flow Layout Delegate

extension ReaderTopicsCardCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForCell(title: data[indexPath.row].title)
    }

    // Calculates the dynamic size of the collection view cell based on the provided title
    private func sizeForCell(title: String) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: ReaderSuggestedTopicsStyleGuide.topicFont
        ]

        let title: NSString = title as NSString

        var size = title.size(withAttributes: attributes)
        size.height += (CellConstants.marginY * 2)
        if RemoteFeatureFlag.readerImprovements.enabled() {
            size.height += 2 // to account for the top & bottom border width
        }

        // Prevent 1 token from being too long
        let maxWidth = collectionView.bounds.width * CellConstants.maxWidthMultiplier
        let width = min(size.width, maxWidth)
        size.width = width + (CellConstants.marginX * 2)
        if RemoteFeatureFlag.readerImprovements.enabled() {
            size.width += 2 // to account for the leading & trailing border width
        }

        return size
    }

    private struct CellConstants {
        static let maxWidthMultiplier: CGFloat = 0.8
        static let marginX: CGFloat = 16
        static let marginY: CGFloat = 8
    }
}

private extension String {
    // MARK: Accessibility Identifiers Constants
    static let topicsCardCellIdentifier = "topics-card-cell-button"
}

// MARK: - New Collection View Cell

class ReaderTopicCardCollectionViewCell: UICollectionViewCell, ReusableCell {

    lazy var titleLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.adjustsFontForContentSizeCategory = true
        $0.font = WPStyleGuide.fontForTextStyle(.footnote)
        $0.textColor = .label
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return $0
    }(UILabel())

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleLabel)
        contentView.pinSubviewToAllEdges(titleLabel, insets: .init(top: 8.0, left: 16.0, bottom: 8.0, right: 16.0))

        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 5.0
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.separator.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - New Collection View Layout

class ReaderTagsCollectionViewLayout: UICollectionViewLayout {

    // MARK: Properties

    var interitemSpacing: CGFloat = .zero

    var lineSpacing: CGFloat = .zero

    weak var delegate: UICollectionViewDelegateFlowLayout?

    private var itemAttributes = [UICollectionViewLayoutAttributes]()

    private var contentHeight: CGFloat = .zero

    private var maxContentWidth: CGFloat {
        guard let collectionView else {
            return .zero
        }
        return collectionView.bounds.width - (collectionView.contentInset.left + collectionView.contentInset.right)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemAttributes[safe: indexPath.row]
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        itemAttributes.filter { $0.frame.intersects(rect) }
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: maxContentWidth, height: contentHeight)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else {
            return false
        }
        return collectionView.bounds.size != newBounds.size
    }

    override func invalidateLayout() {
        contentHeight = 0.0
        itemAttributes.removeAll()
        super.invalidateLayout()
    }

    override func prepare() {
        super.prepare()

        // reset any stored attributes since we're doing a recalculation.
        itemAttributes.removeAll()

        guard let collectionView else {
            return
        }

        let numberOfItems = collectionView.numberOfItems(inSection: .zero)
        let insets = collectionView.contentInset

        var rowCount: CGFloat = 0
        var currentLineWidth: CGFloat = .zero
        var size: CGSize = .zero

        for row in 0..<numberOfItems {
            let indexPath = IndexPath(row: row, section: .zero)
            size = delegate?.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? .zero
            var frame = CGRect(origin: .zero, size: size)

            // if it exceeds maximum width, then add a new line.
            if (currentLineWidth + size.width) > maxContentWidth {
                rowCount += 1
                currentLineWidth = 0.0
            }

            frame.origin.x = insets.left + currentLineWidth
            frame.origin.y = insets.top + (rowCount * (size.height + lineSpacing))

            let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attribute.frame = frame
            itemAttributes.append(attribute)

            // update current width buffer for the next item.
            currentLineWidth += (size.width + interitemSpacing)
        }

        // update total content height.
        contentHeight = insets.top + ((rowCount + 1) * size.height) + (rowCount * lineSpacing) + insets.bottom
    }

}
