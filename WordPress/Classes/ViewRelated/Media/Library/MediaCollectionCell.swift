import UIKit

final class MediaCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private var viewModel: MediaCollectionCellViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .systemGroupedBackground

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.accessibilityIgnoresInvertColors = true

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(imageView)
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

    func configure(viewModel: MediaCollectionCellViewModel) {
        self.viewModel = viewModel

        guard viewModel.mediaType == .image || viewModel.mediaType == .video else {
            // TODO: Add support for other asset types
            return
        }

        loadImage(viewModel: viewModel)
    }

    private func loadImage(viewModel: MediaCollectionCellViewModel) {
        if let image = viewModel.getCachedImage() {
            // Display with no animations. It should happen often thanks to prefetchig
            imageView.image = image
            backgroundColor = .clear
        } else {
            let mediaID = viewModel.mediaID
            viewModel.onLoadingFinished = { [weak self] image in
                guard let self, self.viewModel?.mediaID == mediaID else { return }

                // TODO: Display an asset-specific placeholder on error
                guard let image else { return }
                self.imageView.alpha = 0
                UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction]) {
                    self.imageView.image = image
                    self.imageView.alpha = 1
                    self.backgroundColor = .clear
                }
            }
            viewModel.loadThumbnail()
        }
    }
}
