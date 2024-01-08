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

    static var defaultNibName: String { "ReaderTopicsNewCardCell" }

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

        configureForNewDesign()
    }

    private func applyStyles() {
        headerLabel.font = WPStyleGuide.fontForTextStyle(.footnote)

        containerView.backgroundColor = .secondarySystemBackground
        headerLabel.backgroundColor = .secondarySystemBackground
        collectionView.backgroundColor = .secondarySystemBackground

        backgroundColor = .clear
        contentView.backgroundColor = .systemBackground
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
    }

    private func refreshData() {
        collectionView.reloadData()
    }

    private struct Constants {
        static let title = NSLocalizedString("You might like", comment: "A suggestion of topics the user might like")

        static let reuseIdentifier = ReaderInterestsCollectionViewCell.defaultReuseID
    }
}

// MARK: - Collection View: Datasource & Delegate
extension ReaderTopicsCardCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReaderTopicCardCollectionViewCell.cellReuseIdentifier(), for: indexPath) as? ReaderTopicCardCollectionViewCell else {
            return UICollectionViewCell()
        }

        let title = data[indexPath.row].title
        cell.titleLabel.text = title
        cell.titleLabel.accessibilityIdentifier = .topicsCardCellIdentifier
        cell.titleLabel.accessibilityTraits = .button

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
        size.height += (CellConstants.marginY * 2) + 2

        // Prevent 1 token from being too long
        let maxWidth = collectionView.bounds.width * CellConstants.maxWidthMultiplier
        let width = min(size.width, maxWidth)
        size.width = width + (CellConstants.marginX * 2) + 2

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
        $0.numberOfLines = 1
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return $0
    }(UILabel())

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleLabel)
        contentView.pinSubviewToAllEdges(titleLabel, insets: .init(top: 8.0, left: 16.0, bottom: 8.0, right: 16.0))

        contentView.layer.cornerRadius = 5.0
        contentView.layer.borderWidth = 1.0
        updateColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let previousTraitCollection,
           traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateColors() {
        contentView.backgroundColor = .clear
        contentView.layer.borderColor = UIColor(light: .separator, dark: Constants.darkModeSeparatorColor).cgColor
    }

    private struct Constants {
        // This is a customized `.separator` color with the alpha updated to 1.0.
        // With the default color on top of the gray background, the border appears almost invisible on certain devices.
        // More context: p1697541472738849-slack-C05N140C8H5
        static let darkModeSeparatorColor = UIColor(red: 0.33, green: 0.33, blue: 0.35, alpha: 1.0)
    }
}

// MARK: - New Collection View Layout

/// This tries to achieve a horizontal `UIStackView` layout that can automatically wrap into a new line.
///
/// Note that this depends on the collection view cells having the same height.
/// Different cell heights are not supported yet by this layout.
class ReaderTagsCollectionViewLayout: UICollectionViewLayout {

    // MARK: Properties

    var interitemSpacing: CGFloat = .zero

    var lineSpacing: CGFloat = .zero

    private var isRightToLeft: Bool {
        let layoutDirection = collectionView?.traitCollection.layoutDirection ?? .leftToRight
        return layoutDirection == .rightToLeft
    }

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
        var itemHeight: CGFloat = 0.0
        var availableLineWidth = maxContentWidth

        for index in 0..<numberOfItems {
            let indexPath = IndexPath(row: index, section: .zero)
            let size = delegate?.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? .zero
            var frame = CGRect(origin: .zero, size: size)

            if itemHeight == 0 {
                itemHeight = size.height
            }

            // check if the size will exceed available line width
            if interitemSpacing + size.width > availableLineWidth {
                rowCount += 1
                availableLineWidth = maxContentWidth
            }

            // at this point, we know that the item's width + line spacing fits into the current line.
            frame.origin.y = insets.top + rowCount * (size.height + lineSpacing)
            frame.origin.x = {
                if isRightToLeft {
                    return availableLineWidth - size.width - insets.right
                }
                return insets.left + maxContentWidth - availableLineWidth
            }()

            // add a layout attribute with the current item's frame.
            let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attribute.frame = frame
            itemAttributes.append(attribute)

            // update the available line width for the next item.
            availableLineWidth -= (interitemSpacing + size.width)
        }

        // update total content height.
        contentHeight = insets.top + ((rowCount + 1) * itemHeight) + (rowCount * lineSpacing) + insets.bottom
    }

}
