import UIKit

final class MediaCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private var media: Media?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .systemGroupedBackground

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.pinSubviewToAllEdges(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        backgroundColor = .systemGroupedBackground
    }

    func configure(
        media: Media,
        viewModel: MediaCollectionCellViewModel,
        targetSize: CGSize
    ) {
        // TODO: Add support for other asset types
        if let image = viewModel.getCachedImage() {
            // Display with no animations. It should happen often thanks to prefetchig
            imageView.image = image
        } else {
            viewModel.onLoadingFinished = { [weak self] image in
                guard let self else { return }
                // TODO: Display an asset-specific placeholder on error
                UIView.animate(withDuration: 0.2) {
                    self.imageView.image = image
                    self.backgroundColor = image == nil ? .systemGroupedBackground : .clear
                }
            }
            viewModel.loadThumbnail(targetSize: targetSize)
        }
    }
}
