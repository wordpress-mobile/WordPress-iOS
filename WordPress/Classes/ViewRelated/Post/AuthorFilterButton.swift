import UIKit

/// Displays an author gravatar image with a dropdown arrow.
///
class AuthorFilterButton: UIControl {
    private let authorImageView: CircularImageView = {
        let imageView = CircularImageView(image: UIImage.gravatarPlaceholderImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        return imageView
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.makeChevronDownImage(with: WPStyleGuide.greyDarken10(), size: Metrics.chevronSize))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.contentMode = .bottom

        return imageView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.stackViewSpacing

        return stackView
    }()

    override var intrinsicContentSize: CGSize {
        return Metrics.contentSize
    }

    init() {
        super.init(frame: .zero)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        stackView.addArrangedSubview(authorImageView)
        stackView.addArrangedSubview(chevronImageView)
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.leadingPadding),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            authorImageView.widthAnchor.constraint(equalToConstant: Metrics.gravatarSize.width),
            authorImageView.heightAnchor.constraint(equalToConstant: Metrics.gravatarSize.height),
            widthAnchor.constraint(equalToConstant: intrinsicContentSize.width),
            chevronImageView.heightAnchor.constraint(equalToConstant: Metrics.chevronSize.height + Metrics.chevronVerticalPadding)
            ])
    }

    enum Metrics {
        static let chevronSize = CGSize(width: 10.0, height: 5.0)
        static let contentSize = CGSize(width: 72.0, height: 44.0)
        static let gravatarSize = CGSize(width: 28.0, height: 28.0)
        static let stackViewSpacing: CGFloat = 7.0
        static let chevronVerticalPadding: CGFloat = 2.0
        static let leadingPadding: CGFloat = 12.0
    }
}

fileprivate extension UIImage {
    // Draws a small down facing arrow
    static func makeChevronDownImage(with color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            color.setStroke()
            let path = UIBezierPath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            path.close()
            path.fill()
        }
        return image
    }
}
