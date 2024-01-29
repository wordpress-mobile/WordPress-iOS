import UIKit

/// Use this UIButton subclass to set a custom background for the button image, different from tintColor and backgroundColor.
/// If there's not image, it has no effect. Supports only circular images.
class CircularImageButton: UIButton {

    private lazy var imageBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Sets a custom circular background color below the imageView, different from the button background or tint color
    /// - Parameters:
    ///   - color: the custom background color
    ///   - ratio: the extent of the background view that lays below the button image view (default: 0.75 of the image view)
    func setImageBackgroundColor(_ color: UIColor, ratio: CGFloat = 0.75) {
        guard let imageView = imageView else {
            return
        }
        imageBackgroundView.backgroundColor = color
        insertSubview(imageBackgroundView, belowSubview: imageView)
        imageBackgroundView.clipsToBounds = true
        imageBackgroundView.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            imageBackgroundView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            imageBackgroundView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            imageBackgroundView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ratio),
            imageBackgroundView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ratio),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard imageView != nil else {
            return
        }
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.frame.height / 2
    }
}
