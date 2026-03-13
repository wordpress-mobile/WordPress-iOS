import UIKit
import Gifu
import WordPressUI

final class LightboxImageScrollView: UIScrollView, UIScrollViewDelegate {
    let imageView = GIFImageView()

    var onDismissTapped: (() -> Void)?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configuration

    func configure(with image: UIImage) {
        imageView.configure(image: image)
        configureImageView()
    }

    private func setupView() {
        addSubview(imageView)

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true

        delegate = self
        isMultipleTouchEnabled = true
        minimumZoomScale = 1
        maximumZoomScale = 3
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        panGestureRecognizer.isEnabled = false

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didRecognizeDoubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTapRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didRecognizeTap))
        addGestureRecognizer(tapRecognizer)

        tapRecognizer.require(toFail: doubleTapRecognizer)
    }

    // MARK: Recognizers

    @objc private func didRecognizeDoubleTap(_ recognizer: UITapGestureRecognizer) {
        let zoomScale = zoomScale > minimumZoomScale ? minimumZoomScale : maximumZoomScale
        let width = bounds.size.width / zoomScale
        let height = bounds.size.height / zoomScale

        let location = recognizer.location(in: imageView)
        let x = location.x - (width / 2.0)
        let y = location.y - (height / 2.0)

        let rect = CGRect(x: x, y: y, width: width, height: height)
        zoom(to: rect, animated: true)
    }

    @objc private func didRecognizeTap(_ recognizer: UITapGestureRecognizer) {
        onDismissTapped?()
    }

    // MARK: Layout

    func configureLayout() {
        contentSize = bounds.size
        imageView.frame = bounds
        zoomScale = minimumZoomScale
        panGestureRecognizer.isEnabled = false

        configureImageView()
    }

    private func configureImageView() {
        guard let image = imageView.image else {
            return centerImageView()
        }

        let imageViewSize = imageView.frame.size
        let imageSize = image.size
        let actualImageSize: CGSize

        if imageSize.width / imageSize.height > imageViewSize.width / imageViewSize.height {
            actualImageSize = CGSize(
                width: imageViewSize.width,
                height: imageViewSize.width / imageSize.width * imageSize.height)
        } else {
            actualImageSize = CGSize(
                width: imageViewSize.height / imageSize.height * imageSize.width,
                height: imageViewSize.height)
        }

        imageView.frame = CGRect(origin: CGPoint.zero, size: actualImageSize)

        centerImageView()
    }

    private func centerImageView() {
        var newFrame = imageView.frame
        if newFrame.size.width < bounds.size.width {
            newFrame.origin.x = (bounds.size.width - newFrame.size.width) / 2.0
        } else {
            newFrame.origin.x = 0.0
        }

        if newFrame.size.height < bounds.size.height {
            newFrame.origin.y = (bounds.size.height - newFrame.size.height) / 2.0
        } else {
            newFrame.origin.y = 0.0
        }
        imageView.frame = newFrame
    }

    // MARK: UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        panGestureRecognizer.isEnabled = false
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        panGestureRecognizer.isEnabled = scale > minimumZoomScale
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
    }
}
