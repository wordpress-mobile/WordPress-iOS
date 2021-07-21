import UIKit
import Gutenberg

protocol CategorySectionTableViewCellDelegate: AnyObject {
    func didSelectItemAt(_ position: Int, forCell cell: CategorySectionTableViewCell, slug: String)
    func didDeselectItem(forCell cell: CategorySectionTableViewCell)
    func accessibilityElementDidBecomeFocused(forCell cell: CategorySectionTableViewCell)
    var selectedPreviewDevice: PreviewDeviceSelectionViewController.PreviewDevice { get }
}

protocol Thumbnail {
    var urlDesktop: String? { get }
    var urlTablet: String? { get }
    var urlMobile: String? { get }
    var slug: String { get }
}

protocol CategorySection {
    var categorySlug: String { get }
    var title: String { get }
    var emoji: String? { get }
    var description: String? { get }
    var thumbnails: [Thumbnail] { get }
    var scrollOffset: CGPoint { get set }
}

class CategorySectionTableViewCell: UITableViewCell {

    static let cellReuseIdentifier = "\(CategorySectionTableViewCell.self)"
    static let nib = UINib(nibName: "\(CategorySectionTableViewCell.self)", bundle: Bundle.main)
    static let expectedThumbnailSize = CGSize(width: 160.0, height: 240)
    static let estimatedCellHeight: CGFloat = 310.0

    @IBOutlet weak var categoryTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    weak var delegate: CategorySectionTableViewCellDelegate?

    private var thumbnails = [Thumbnail]() {
        didSet {
            collectionView.reloadData()
        }
    }

    var section: CategorySection? = nil {
        didSet {
            thumbnails = section?.thumbnails ?? []
            categoryTitle.text = section?.title
            collectionView.contentOffset = section?.scrollOffset ?? .zero
        }
    }

    var isGhostCell: Bool = false

    override func prepareForReuse() {
        section?.scrollOffset = collectionView.contentOffset
        delegate = nil
        super.prepareForReuse()
        collectionView.contentOffset.x = 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(CollapsableHeaderCollectionViewCell.nib, forCellWithReuseIdentifier: CollapsableHeaderCollectionViewCell.cellReuseIdentifier)
        categoryTitle.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.headline, fontWeight: .semibold)
        categoryTitle.layer.masksToBounds = true
        categoryTitle.layer.cornerRadius = 4
    }

    private func deselectItem(_ indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView(collectionView, didDeselectItemAt: indexPath)
    }

    func deselectItems() {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return }
        selectedItems.forEach { (indexPath) in
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }

    func selectItemAt(_ position: Int) {
        collectionView.selectItem(at: IndexPath(item: position, section: 0), animated: false, scrollPosition: [])
    }
}

extension CategorySectionTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView.cellForItem(at: indexPath)?.isSelected ?? false {
            deselectItem(indexPath)
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let slug = section?.categorySlug else { return }
        delegate?.didSelectItemAt(indexPath.item, forCell: self, slug: slug)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        delegate?.didDeselectItem(forCell: self)
    }
}

extension CategorySectionTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CategorySectionTableViewCell.expectedThumbnailSize
     }
}

extension CategorySectionTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isGhostCell ? 1 : thumbnails.count
    }

    func collectionView(_ LayoutPickerCategoryTableViewCell: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellReuseIdentifier = CollapsableHeaderCollectionViewCell.cellReuseIdentifier
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? CollapsableHeaderCollectionViewCell else {
            fatalError("Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(CollapsableHeaderCollectionViewCell.self). Please make sure the collection view is registering the correct nib before loading the data")
        }
        guard !isGhostCell else {
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
            return cell
        }

        let thumbnail = thumbnails[indexPath.row]
        cell.previewURL = thumbnailUrl(forThumbnail: thumbnail)
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = thumbnail.slug
        return cell
    }

    private func thumbnailUrl(forThumbnail thumbnail: Thumbnail) -> String? {
        guard let delegate = delegate else { return thumbnail.urlDesktop }
        switch delegate.selectedPreviewDevice {
        case .desktop:
            return thumbnail.urlDesktop
        case .tablet:
            return thumbnail.urlTablet
        case .mobile:
            return thumbnail.urlMobile
        }
    }
}

/// Accessibility
extension CategorySectionTableViewCell {
    override func accessibilityElementDidBecomeFocused() {
        delegate?.accessibilityElementDidBecomeFocused(forCell: self)
    }
}

class AccessibleCollectionView: UICollectionView {
    override func accessibilityElementCount() -> Int {
        guard let dataSource = dataSource else {
            return 0
        }

        return dataSource.collectionView(self, numberOfItemsInSection: 0)
    }
}
