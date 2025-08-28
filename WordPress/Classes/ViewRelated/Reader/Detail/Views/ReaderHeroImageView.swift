import Foundation
import AsyncImageKit
import WordPressUI

final class ReaderHeroImageView: UIView {
    let contentView = UIView()
    let imageView = AsyncImageView()

    // Make sure it's clipped at the bottom but not immediatelly at the top
    static let topPadding: CGFloat = 200

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(contentView)
        contentView.pinEdges(insets: UIEdgeInsets(.top, Self.topPadding))
        contentView.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: ReaderPostCell.coverAspectRatio).isActive = true

        contentView.addSubview(imageView)
        imageView.pinEdges()

        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
