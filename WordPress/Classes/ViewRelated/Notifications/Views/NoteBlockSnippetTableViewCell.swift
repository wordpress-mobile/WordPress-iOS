import Foundation


@objc public class NoteBlockSnippetTableViewCell : NoteBlockTableViewCell
{
    // MARK: - Public Properties
    public var name: String? {
        didSet {
            nameLabel.text  = name != nil ? name! : String()
        }
    }
    public var snippet: String? {
        didSet {
            snippetLabel.text = snippet != nil ? snippet! :  String()
        }
    }
    
    // MARK: - Public Methods
    public func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }
        
        let placeholderImage = UIImage(named: placeholderName)
        let success = { (image: UIImage) in
            self.gravatarImageView.displayImageWithFadeInAnimation(image)
        }

        gravatarImageView.downloadImage(url, placeholderName: placeholderName, success: success, failure: nil)
        
        gravatarURL = url
    }
    
    // MARK: - View Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        accessoryType                   = .DisclosureIndicator
        contentView.autoresizingMask    = .FlexibleHeight | .FlexibleWidth
        
        backgroundColor                 = WPStyleGuide.Notifications.Colors.blockBackground
        nameLabel.font                  = WPStyleGuide.Notifications.Fonts.blockRegular
        nameLabel.textColor             = WPStyleGuide.Notifications.Colors.blockText
        snippetLabel.font               = WPStyleGuide.Notifications.Fonts.blockItalics
        snippetLabel.textColor          = WPStyleGuide.Notifications.Colors.quotedText
    }
    

    // MARK: - Private
    private let placeholderName:                    String = "gravatar"
    private var gravatarURL:                        NSURL?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var gravatarImageView:   UIImageView!
    @IBOutlet private weak var nameLabel:           UILabel!
    @IBOutlet private weak var snippetLabel:        UILabel!
}
