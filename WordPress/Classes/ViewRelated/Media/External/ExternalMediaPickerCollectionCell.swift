import UIKit

final class ExternalMediaPickerCollectionCell: UICollectionViewCell {
    private let imageView = ImageView()

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

    func configure(_ viewModel: ExternalMediaPickerCollectionCellViewModel, size: CGSize) {
        imageView.setImage(with: viewModel.imageURL, size: size)
    }
}

final class ExternalMediaPickerCollectionCellViewModel {
    let imageURL: URL

    init(imageURL: URL) {
        self.imageURL = imageURL
    }
}
