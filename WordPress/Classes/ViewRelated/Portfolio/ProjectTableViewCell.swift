import UIKit

class ProjectTableViewCell: BasePageListCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var featuredImageView: UIImageView!
    
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
        titleLabel.attributedText = NSAttributedString(string: str, attributes: WPStyleGuide.pageCellTitleAttributes() as? [String: Any])
    }

    func configureImage() {
        guard let post = self.post else {
            return
        }
        
        let rightPost = getRightPost(from: post)
        if let featuredImage = rightPost.featuredImage {
            featuredImage.image(with: .zero, completionHandler: { image, error in
                if error == nil {
                    self.featuredImageView.image = image
                }
            })
        } else {
            self.featuredImageView.image = nil
        }
    }

    func getRightPost(from post: AbstractPost) -> AbstractPost {
        return post.hasRevision() ? post.revision! : post
    }
}
