import UIKit
import Gutenberg

protocol LayoutPickerSectionTableViewCellDelegate: class {
    func didSelectLayoutAt(_ position: Int, forCell cell: LayoutPickerSectionTableViewCell)
    func didDeselectItem(forCell cell: LayoutPickerSectionTableViewCell)
    func accessibilityElementDidBecomeFocused(forCell cell: LayoutPickerSectionTableViewCell)
}

class LayoutPickerSectionTableViewCell: UITableViewCell {

    static var cellReuseIdentifier: String {
        return "LayoutPickerSectionTableViewCell"
    }

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerSectionTableViewCell", bundle: Bundle.main)
    }

    @IBOutlet weak var categoryTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    weak var delegate: LayoutPickerSectionTableViewCellDelegate?

    private var layouts = [GutenbergLayout]() {
        didSet {
            collectionView.reloadData()
        }
    }
    var section: GutenbergLayoutSection? = nil {
        didSet {
            layouts = section?.layouts ?? []
            categoryTitle.text = section?.section.description ?? ""
            collectionView.contentOffset = section?.scrollOffset ?? .zero
        }
    }

    override func prepareForReuse() {
        section?.scrollOffset = collectionView.contentOffset
        delegate = nil
        super.prepareForReuse()
        collectionView.contentOffset.x = 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(LayoutPickerCollectionViewCell.nib, forCellWithReuseIdentifier: LayoutPickerCollectionViewCell.cellReuseIdentifier)
        categoryTitle.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.headline, fontWeight: .semibold)

        if #available(iOS 13.0, *) {
            styleShadow()
        } else {
            styleShadowLightMode()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                styleShadow()
            }
        }
    }

    @available(iOS 13.0, *)
    func styleShadow() {
        if traitCollection.userInterfaceStyle == .dark {
            styleShadowDarkMode()
        } else {
            styleShadowLightMode()
        }
    }

    func styleShadowLightMode() {
        collectionView.layer.shadowColor = UIColor.black.cgColor
        collectionView.layer.shadowRadius = 36
        collectionView.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        collectionView.layer.shadowOpacity = 0.1
        collectionView.backgroundColor = nil
    }

    func styleShadowDarkMode() {
        collectionView.layer.shadowColor = nil
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

extension LayoutPickerSectionTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView.cellForItem(at: indexPath)?.isSelected ?? false {
            deselectItem(indexPath)
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectLayoutAt(indexPath.item, forCell: self)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        delegate?.didDeselectItem(forCell: self)
    }
}

extension LayoutPickerSectionTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 148.0, height: 230.0)
     }
}

extension LayoutPickerSectionTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30 // Static layouts currently only have one layout per category. Adding multiple in here to help test
    }

    func collectionView(_ LayoutPickerCategoryTableViewCell: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LayoutPickerCollectionViewCell.cellReuseIdentifier, for: indexPath) as! LayoutPickerCollectionViewCell
        let layout = layouts[0] // Static layouts currently only have one layout per category. Reusing the first to help test
        cell.layout = layout
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = layout.title + " \(indexPath.item)"
        return cell
    }
}

/// Accessibility
extension LayoutPickerSectionTableViewCell {
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
