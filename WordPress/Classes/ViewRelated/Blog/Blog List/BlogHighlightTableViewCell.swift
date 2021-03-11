import UIKit
import Combine

@objc class BlogHighlightTableViewCell: UITableViewCell {

    var cancellable: Cancellable?

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    var highlights: [String] = [] {
        didSet {
            guard oldValue != highlights else {
                return
            }

            collectionView.reloadData()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()

        // Configure collection view
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ReaderInterestsCollectionViewCell.defaultNib,
                                forCellWithReuseIdentifier: ReaderInterestsCollectionViewCell.defaultReuseID)
    }

    func configure(blog: Blog) {
        let displayURL = blog.displayURL as String? ?? ""
        if let name = blog.settings?.name?.nonEmptyString() {
            titleLabel.text = name
            subtitleLabel.text = displayURL
        } else {
            titleLabel.text = displayURL
            subtitleLabel.text = nil
        }

        iconImageView.downloadSiteIcon(for: blog)
    }

    private func applyStyles() {
        titleLabel.textColor = .text
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)

        subtitleLabel.textColor = .textSubtle
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)

        collectionView.backgroundColor = .listForeground
    }

    private struct Constants {
        static let reuseIdentifier = ReaderInterestsCollectionViewCell.defaultReuseID
    }
}

extension BlogHighlightTableViewCell: NibReusable {

    @objc static var defaultReuseID: String {
        return String(describing: self)
    }

    @objc static var defaultNibName: String {
        return String(describing: self)
    }

    @objc static var defaultBundle: Bundle {
        return Bundle.main
    }

    @objc static var defaultNib: UINib {
        return UINib(nibName: defaultNibName, bundle: defaultBundle)
    }

}

// MARK: - Collection View: Datasource & Delegate

extension BlogHighlightTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.reuseIdentifier,
                                                            for: indexPath) as? ReaderInterestsCollectionViewCell else {
            fatalError("Expected a ReaderInterestsCollectionViewCell for identifier: \(Constants.reuseIdentifier)")
        }

        let title = highlights[indexPath.row]
        cell.label.text = title
        cell.label.accessibilityTraits = .button

        cell.label.font = WPStyleGuide.fontForTextStyle(.footnote)
        cell.label.textColor = .text
        cell.label.layer.backgroundColor = UIColor.listBackground.cgColor

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
        return highlights.count
    }
}

// MARK: - Collection View: Flow Layout Delegate

extension BlogHighlightTableViewCell: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForCell(title: highlights[indexPath.row])
    }

    // Calculates the dynamic size of the collection view cell based on the provided title
    private func sizeForCell(title: String) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: WPStyleGuide.fontForTextStyle(.footnote)
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
