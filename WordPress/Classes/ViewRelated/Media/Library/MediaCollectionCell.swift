import UIKit

final class MediaCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private var viewModel: MediaCollectionCellViewModel?

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

        viewModel?.cancelLoading()
        viewModel = nil

        imageView.image = nil
        backgroundColor = .systemGroupedBackground
    }

    func configure(viewModel: MediaCollectionCellViewModel, targetSize: CGSize) {
        self.viewModel = viewModel

        guard viewModel.mediaType == .image || viewModel.mediaType == .video else {
            // TODO: Add support for other asset types
            return
        }

        if let image = viewModel.getCachedImage() {
            // Display with no animations. It should happen often thanks to prefetchig
            imageView.image = image
        } else {
            let mediaID = viewModel.mediaID
            viewModel.onLoadingFinished = { [weak self] image in
                guard let self, self.viewModel?.mediaID == mediaID else { return }
                // TODO: Display an asset-specific placeholder on error
                self.imageView.alpha = 0
                UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction]) {
                    self.imageView.image = image
                    self.imageView.alpha = 1
                    self.backgroundColor = image == nil ? .systemGroupedBackground : .clear
                }
            }
            viewModel.loadThumbnail(targetSize: targetSize)
        }
    }
}
