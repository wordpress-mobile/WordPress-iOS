import Foundation
import AsyncImageKit
import WordPressUI

final class ReaderHeroView: UIView {
    let imageView = AsyncImageView()

    private var extensionView: UIView?

    // Make sure the image doesn't go below the status bar
    var estimatedStatusBarOffset: CGFloat {
        traitCollection.horizontalSizeClass == .compact ? 40 : 20
    }

    private(set) var bottomExtensionHeight: CGFloat = 0

    var imageURL: URL?

    private var onTap: ((AsyncImageView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            let extensionView = UIBackgroundExtensionView()
            extensionView.automaticallyPlacesContentView = false
            extensionView.contentView = imageView
            self.extensionView = extensionView

            addSubview(extensionView)
        } else {
            addSubview(imageView)
        }
#else
        addSubview(imageView)
#endif

        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        extensionView?.frame = bounds

        // Enforce the default aspect ratio
        let height = min(280, bounds.width * ReaderPostCell.coverAspectRatio).rounded()

        // Center the image in the container to achieve the parallax effect
        let imageViewFrame = CGRect(
            x: 0,
            // rounded is needed to avoid gaps in the extension view
            y: ((bounds.height - height) / 2 + estimatedStatusBarOffset - bottomExtensionHeight).rounded(),
            width: bounds.width,
            height: height
        )

        if imageViewFrame != imageView.frame {
            imageView.frame = imageViewFrame
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Extend below the header of the article to support corner radius
        let newValue = traitCollection.horizontalSizeClass == .compact ? DesignConstants.radius(.large) : 0
        if bottomExtensionHeight != newValue {
            bottomExtensionHeight = newValue
            setNeedsLayout()
        }
    }

    func configureTapGesture(in scrollView: UIScrollView, _ closure: @escaping (AsyncImageView) -> Void) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        scrollView.addGestureRecognizer(tap)

        self.onTap = closure
    }

    @objc private func didTap() {
        onTap?(imageView)
    }
}

extension ReaderHeroView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: self)
        let isOutsideView = !imageView.frame.contains(touchPoint)

        /// Do not accept the touch if outside the featured image view
        return isOutsideView == false
    }
}
