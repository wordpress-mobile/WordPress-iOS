import Foundation
import UIKit


/// Displays an Image with a capped size, defined by the maximumSize property.
///
class MediaView: UIView {
    // MARK: - Properties

    /// Defines the maximum size that this view might occupy.
    ///
    var maximumSize = CGSize(width: 90, height: 90) {
        didSet {
            refreshContentSize()
        }
    }

    /// The image that should be displayed
    ///
    fileprivate var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            refreshContentSize()
        }
    }

    /// Internal imageView Instance
    ///
    fileprivate lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()

    /// Internal Width Constraint
    ///
    fileprivate var widthConstraint: NSLayoutConstraint!

    /// Internal Height Constraint
    ///
    fileprivate var heightConstraint: NSLayoutConstraint!

    /// Internal activityIndicator Instance
    ///
    fileprivate let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)



    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }



    // MARK: - Public Methods

    /// Displays a spinner at the center of this view, and dims the imageView
    ///
    func startSpinner() {
        activityIndicatorView.startAnimating()
        imageView.alpha = Constants.alphaDimming
    }

    /// Stops the spinner, and restores the original alpha
    ///
    func stopSpinner() {
        activityIndicatorView.stopAnimating()
        imageView.alpha = Constants.alphaFull
    }

    /// Workaround to prevent having a zero contentSize before the image is effectively loaded
    ///
    override var intrinsicContentSize: CGSize {
        return maximumSize
    }

    /// Resizes -to fit screen- and displays given image
    ///
    func resizeIfNeededAndDisplay(_ image: UIImage) {
        let scale = UIScreen.main.scale
        let scaledMaximumSize = CGSize(width: maximumSize.width * scale, height: maximumSize.height * scale)

        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let resizedImage = image.resizeWithMaximumSize(scaledMaximumSize)

            DispatchQueue.main.async {
                self.image = resizedImage
            }
        }
    }


    // MARK: - Private Helpers

    fileprivate func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        widthConstraint = widthAnchor.constraint(equalToConstant: maximumSize.width)
        heightConstraint = heightAnchor.constraint(equalToConstant: maximumSize.height)

        widthConstraint.isActive = true
        heightConstraint.isActive = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    fileprivate func refreshContentSize() {
        widthConstraint.constant = maximumSize.width
        heightConstraint.constant = maximumSize.height
    }



    // MARK: - Private Enums

    fileprivate enum Constants {
        static let alphaDimming = CGFloat(0.3)
        static let alphaFull = CGFloat(1.0)
    }
}
