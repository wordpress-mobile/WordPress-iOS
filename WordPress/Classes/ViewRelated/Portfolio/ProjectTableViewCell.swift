import UIKit

class ProjectTableViewCell: BasePageListCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var featuredImageView: UIImageView!
    @IBOutlet var featuredImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet var featuredImageHeightConstraint: NSLayoutConstraint!

    override var post: AbstractPost? {
        didSet {
            configureTitle()
            configureImage()
        }
    }

    // MARK: - Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()

        featuredImageView.clipsToBounds = true
        featuredImageView.contentMode = .scaleAspectFill
    }

    // MARK: - Configuration

    func applyStyles() {
        WPStyleGuide.applyPageTitleStyle(titleLabel)
    }

    func configureTitle() {
        guard let post = self.post else {
            return
        }

        let rightPost = getRightPost(from: post)
        let str = rightPost.titleForDisplay() ?? ""
        titleLabel.attributedText = NSAttributedString(string: str, attributes: WPStyleGuide.pageCellTitleAttributes() as? [NSAttributedStringKey: Any])
    }

    func configureImage() {
        guard let post = self.post else {
            return
        }

        let rightPost = getRightPost(from: post)

        if let featuredImagePath = rightPost.pathForDisplayImage, let featuredImageURL = URL(string: featuredImagePath) {
            if post.blog.isHostedAtWPcom {
                let desiredWidth = featuredImageWidthConstraint.constant
                let desiredHeight = featuredImageHeightConstraint.constant
                if post.isPrivate() {
                    let scale = UIScreen.main.scale
                    let scaledSize = CGSize(width: desiredWidth * scale, height: desiredHeight * scale)
                    let url = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: featuredImageURL)
                    if let request = PrivateSiteURLProtocol.requestForPrivateSite(from: url) {
                        featuredImageView.setImageWith(request, placeholderImage: nil, success: nil, failure: nil)
                    }
                } else {
                    let size = CGSize(width: desiredWidth, height: desiredHeight)
                    if let url = PhotonImageURLHelper.photonURL(with: size, forImageURL: featuredImageURL) {
                        featuredImageView.setImageWith(url, placeholderImage: nil)
                    }
                }
            } else { // Not supported outside of wordpress.com
                self.featuredImageView.image = nil
            }
        } else {
            self.featuredImageView.image = nil
        }
    }

    func getRightPost(from post: AbstractPost) -> AbstractPost {
        return post.hasRevision() ? post.revision! : post
    }
}
