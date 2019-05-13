import UIKit

class PostCell: UITableViewCell, ConfigurablePostView {
    @IBOutlet weak var featuredImage: CachedAnimatedImageView!
    @IBOutlet weak var upperBorder: UIView!
    @IBOutlet weak var bottomBorder: UIView!

    lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImage, gifStrategy: .mediumGIFs)
    }()

    var post: Post!

    func configure(with post: Post) {
        self.post = post

        configureFeaturedImage()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        WPStyleGuide.applyPostCardStyle(self)

        [upperBorder, bottomBorder].forEach { border in
            border?.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            border?.backgroundColor = WPStyleGuide.postCardBorderColor()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
        setNeedsDisplay()
    }

    private func configureFeaturedImage() {
        let post = self.post.latest()

        if let url = post.featuredImageURLForDisplay(),
            let desiredWidth = UIApplication.shared.keyWindow?.frame.size.width {
            featuredImage.isHidden = false
            imageLoader.loadImage(with: url, from: post, preferredSize: CGSize(width: desiredWidth, height: featuredImage.frame.height))
        } else {
            featuredImage.isHidden = true
        }
    }
}
