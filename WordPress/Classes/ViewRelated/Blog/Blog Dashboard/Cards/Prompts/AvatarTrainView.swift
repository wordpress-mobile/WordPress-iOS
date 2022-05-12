import UIKit

/// A view that shows a train of circular avatar images.
///
final class AvatarTrainView: UIView {

    // MARK: Private Properties

    private var avatarURLs: [URL?]

    private var placeholderImage: UIImage

    private lazy var avatarStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Constants.imageViewSpacing

        return stackView
    }()

    /// The border layer "cuts" into the image height, reducing the displayable area.
    /// Therefore, we need to account for the border width (on both sides) to keep the image displayed in the intended size.
    var imageHeight: CGFloat {
        Constants.avatarDiameter + (2 * Constants.borderWidth)
    }

    // MARK: Public Methods

    init(avatarURLs: [URL?], placeholderImage: UIImage? = nil) {
        self.avatarURLs = avatarURLs
        self.placeholderImage = placeholderImage ?? Constants.placeholderImage
        super.init(frame: .zero)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // redraw border when user interface style changes.
        if let previousTraitCollection = previousTraitCollection,
            previousTraitCollection.userInterfaceStyle != traitCollection.userInterfaceStyle {
            configureAvatarBorders()
        }
    }

    override func layoutSubviews() {
        configureAvatarBorders()
    }

}

// MARK: Private Helpers

private extension AvatarTrainView {

    func setupViews() {
        addSubview(avatarStackView)
        pinSubviewToAllEdges(avatarStackView)
        avatarStackView.addArrangedSubviews(avatarURLs.map { makeAvatarImageView(with: $0) })
    }

    func makeAvatarImageView(with avatarURL: URL? = nil) -> UIImageView {
        let imageView = CircularImageView(image: placeholderImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: imageHeight),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])

        if let avatarURL = avatarURL {
            imageView.downloadImage(from: avatarURL, placeholderImage: placeholderImage)
        }

        return imageView
    }

    func configureAvatarBorders() {
        avatarStackView.arrangedSubviews.forEach { view in
            view.layer.masksToBounds = true
            view.layer.borderWidth = Constants.borderWidth
            view.layer.borderColor = UIColor.listForeground.cgColor
        }
    }

    // MARK: Constants

    struct Constants {
        static let imageViewSpacing: CGFloat = -5
        static let avatarDiameter: CGFloat = 20
        static let borderWidth: CGFloat = 2
        static let placeholderImage: UIImage = .gravatarPlaceholderImage
    }

}
