import UIKit

/// A cell that displays topics the user might like
///
class ReaderTopicsCardCell: UITableViewCell, NibLoadable {
    // Views
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    private(set) var data: [ReaderAbstractTopic] = [] {
        didSet {
            guard oldValue != data else {
                return
            }

            collectionView.reloadData()
        }
    }

    weak var delegate: ReaderTopicsTableCardCellDelegate?

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
    }

    private func applyStyles() {
        headerLabel.font = WPStyleGuide.serifFontForTextStyle(.title2)

        containerView.backgroundColor = .listForeground
        headerLabel.backgroundColor = .listForeground
        collectionView.backgroundColor = .listForeground

        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private struct Constants {
        static let title = NSLocalizedString("You might like", comment: "A suggestion of topics the user might like")

        static let reuseIdentifier = ReaderInterestsCollectionViewCell.defaultReuseID
    }
}

// MARK: - Collection View: Datasource & Delegate
extension ReaderTopicsCardCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.reuseIdentifier,
                                                            for: indexPath) as? ReaderInterestsCollectionViewCell else {
            fatalError("Expected a ReaderInterestsCollectionViewCell for identifier: \(Constants.reuseIdentifier)")
        }

        let title = data[indexPath.row].title

        ReaderSuggestedTopicsStyleGuide.applySuggestedTopicStyle(label: cell.label,
                                                                 with: indexPath.row)

        cell.label.text = title
        cell.label.accessibilityTraits = .button

        // We need to use the calculated size for the height / corner radius because the cell size doesn't change until later
        let size = sizeForCell(title: title)
        cell.label.layer.cornerRadius = size.height * 0.5

        return cell
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            collectionView.reloadData()
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

        // Prevent 1 token from being too long
        let maxWidth = collectionView.bounds.width * CellConstants.maxWidthMultiplier
        let width = min(size.width, maxWidth)
        size.width = width + (CellConstants.marginX * 2)

        return size
    }

    private struct CellConstants {
        static let maxWidthMultiplier: CGFloat = 0.8
        static let marginX: CGFloat = 16
        static let marginY: CGFloat = 8
    }
}
