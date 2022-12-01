import UIKit

extension UIButton {

    private static var closeButtonImage: UIImage {
        let fontForSystemImage = UIFont.systemFont(ofSize: Metrics.closeButtonRadius)
        let configuration = UIImage.SymbolConfiguration(font: fontForSystemImage)

        // fallback to the gridicon if for any reason the system image fails to render
        return UIImage(systemName: Constants.closeButtonSystemName, withConfiguration: configuration) ??
        UIImage.gridicon(.crossCircle, size: CGSize(width: Metrics.closeButtonRadius, height: Metrics.closeButtonRadius))
    }

    static func makeCloseButton() -> UIButton {
        let closeButton = CircularImageButton()

        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.tintColor = Colors.closeButtonTintColor
        closeButton.setImageBackgroundColor(UIColor(light: .black, dark: .white))

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonRadius),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])

        return closeButton
    }

    private enum Constants {
        static let closeButtonSystemName = "xmark.circle.fill"
    }

    private enum Metrics {
        static let closeButtonRadius: CGFloat = 30
    }

    private enum Colors {
        static let closeButtonTintColor = UIColor(
            light: .muriel(color: .gray, .shade5),
            dark: .muriel(color: .jetpackGreen, .shade90)
        )
    }
}
