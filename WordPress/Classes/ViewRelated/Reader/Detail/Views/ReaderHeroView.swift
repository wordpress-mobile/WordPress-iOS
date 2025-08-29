import Foundation
import AsyncImageKit
import WordPressUI

final class ReaderHeroView: UIView {
    let imageView = AsyncImageView()

    private var extensionView: UIView?

    // Make sure the image doesn't go below the status bar
    static let estimatedStatusBarOffset: CGFloat = 44

    static let bottomExtensionHeight = DesignConstants.radius(.large)

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

    override func layoutSubviews() {
        super.layoutSubviews()

        extensionView?.frame = bounds

        // Enforce the default aspect ratio
        let height = min(320, bounds.width * ReaderPostCell.coverAspectRatio).rounded()

        // Center the image in the container to achieve the parallax effect
        let imageViewFrame = CGRect(
            x: 0,
            // rounded is needed to avoid gaps in the extension view
            y: ((bounds.height - height) / 2 + Self.estimatedStatusBarOffset - Self.bottomExtensionHeight).rounded(),
            width: bounds.width,
            height: height
        )

        if imageViewFrame != imageView.frame {
            imageView.frame = imageViewFrame
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
