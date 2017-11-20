import UIKit

class ProjectTableViewCell: BasePageListCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var menuButton: UIButton!
    
    override var post: AbstractPost? {
        didSet {
            configureTitle()
        }
    }
    
    // MARK: - Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyStyles()
    }
    
    // MARK: - Configuration
    
    func applyStyles() {
        WPStyleGuide.applyPageTitleStyle(titleLabel)
    }
    
    func configureTitle() {
        guard let post = self.post else {
            return
        }
        
        let rightPost = post.hasRevision() ? post.revision! : post
        let str = rightPost.titleForDisplay() ?? ""
        titleLabel.attributedText = NSAttributedString(string: str, attributes: WPStyleGuide.pageCellTitleAttributes() as? [String: Any])
    }
}
