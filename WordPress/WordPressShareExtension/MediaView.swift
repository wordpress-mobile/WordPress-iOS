import Foundation
import UIKit


///
///
class MediaView : UIView
{
    ///
    ///
    var maximumSize = CGSizeMake(90, 90) {
        didSet {
            refreshContentSize()
        }
    }

    ///
    ///
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            refreshContentSize()
        }
    }

    ///
    ///
    private let imageView = UIImageView()

    ///
    ///
    private let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

    ///
    ///
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    ///
    ///
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    ///
    ///
    func startSpinner() {
        activityIndicatorView.startAnimating()
        imageView.alpha = Constants.alphaDimming
    }

    ///
    ///
    func stopSpinner() {
        activityIndicatorView.stopAnimating()
        imageView.alpha = Constants.alphaFull
    }

    ///
    ///
    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        imageView.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        imageView.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
        imageView.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        imageView.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true

        addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        activityIndicatorView.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
    }

    ///
    ///
    private func refreshContentSize() {
        let targetSize = (image != nil) ? maximumSize : CGSizeZero
        widthAnchor.constraintEqualToConstant(targetSize.width).active = true
        heightAnchor.constraintEqualToConstant(targetSize.height).active = true
    }


    // MARK: - Private Enums

    private enum Constants {
        static let alphaDimming = CGFloat(0.3)
        static let alphaFull = CGFloat(1.0)
    }
}
