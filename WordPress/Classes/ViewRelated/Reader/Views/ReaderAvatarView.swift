import UIKit

final class ReaderAvatarView: UIView {
    private let asyncImageView = AsyncImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.masksToBounds = true
        backgroundColor = UIColor.white

        layer.borderWidth = 0.5
        layer.borderColor = UIColor.opaqueSeparator.withAlphaComponent(0.5).cgColor

        asyncImageView.configuration.isErrorViewEnabled = false

        addSubview(asyncImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        asyncImageView.frame = bounds
        layer.cornerRadius = bounds.width / 2
    }

    func prepareForReuse() {
        asyncImageView.prepareForReuse()
    }

    func setStaticIcon(_ image: UIImage?, tintColor: UIColor) {
        asyncImageView.configuration.tintColor = .secondaryLabel
        asyncImageView.configuration.contentMode = .center
        asyncImageView.image = image
    }

    func setPlaceholder(_ image: UIImage?) {
        asyncImageView.image = image
    }

    func setImage(with imageURL: URL, size: CGSize? = nil) {
        asyncImageView.setImage(with: imageURL, size: size)
    }
}
