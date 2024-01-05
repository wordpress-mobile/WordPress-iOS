import UIKit

final class ExternalMediaPickerCollectionCell: UICollectionViewCell {
    private let imageView = ImageView()
    private var selectionView: SiteMediaCollectionCellSelectionOverlayView?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.prepareForReuse()
    }

    func configure(imageURL: URL, size: CGSize) {
        imageView.setImage(with: imageURL, size: size)
    }

    func setBadge(_ badge: SiteMediaCollectionCellViewModel.BadgeType?) {
        if let badge {
            let selectionView = getSelectionView()
            selectionView.setBadge(badge)
            selectionView.isHidden = false
        } else {
            selectionView?.isHidden = true
        }
    }

    private func getSelectionView() -> SiteMediaCollectionCellSelectionOverlayView {
        if let selectionView {
            return selectionView
        }
        let selectionView = SiteMediaCollectionCellSelectionOverlayView()
        selectionView.setBadge(.unordered)
        addSubview(selectionView)
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(selectionView)
        self.selectionView = selectionView
        return selectionView
    }
}
