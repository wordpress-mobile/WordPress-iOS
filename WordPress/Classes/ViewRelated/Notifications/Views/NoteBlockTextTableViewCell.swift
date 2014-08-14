import Foundation


@objc public class NoteBlockTextTableViewCell : NoteBlockTableViewCell, DTAttributedTextContentViewDelegate
{
    // MARK: - Private Properties
    @IBOutlet private weak var attributedLabel: DTAttributedLabel!
    private let LabelInsets:                    UIEdgeInsets        = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
    
    // MARK: - Public Properties
    public var onUrlClick: ((NSURL) -> Void)?
    public var attributedText: NSAttributedString! {
        willSet {
            attributedLabel.attributedString = newValue
            setNeedsLayout()
        }
    }
    
    // MARK: - Helper Methods: Override if needed
    public func numberOfLines() -> Int {
        return 0
    }

    public func labelPreferredMaxLayoutWidth() -> CGFloat {
        return CGRectGetWidth(bounds) - LabelInsets.left - LabelInsets.right
    }
    
    // MARK: - Setup Methods
    public override func awakeFromNib() {
        assert(attributedLabel)
        super.awakeFromNib()
        
        backgroundColor                   = WPStyleGuide.notificationBlockBackgroundColor()
        selectionStyle                    = .None
        
        attributedLabel.backgroundColor   = UIColor.clearColor()
        attributedLabel.numberOfLines     = numberOfLines()
        attributedLabel.delegate          = self
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Just in case
        attributedLabel.layoutFrameHeightIsConstrainedByBounds = false
        
        // Manually update DTAttributedLabel's size
        let width = labelPreferredMaxLayoutWidth();
        attributedLabel.frame.size = attributedLabel.suggestedFrameSizeToFitEntireStringConstraintedToWidth(width)
    }
    
    // MARK: - DTAttributedTextContentViewDelegate
    public func attributedTextContentView(attributedTextContentView: DTAttributedTextContentView!, viewForLink url: NSURL!, identifier: String!, frame: CGRect) -> UIView! {
        let linkButton                          = DTLinkButton(frame: frame)
        
        linkButton.URL                          = url
        linkButton.showsTouchWhenHighlighted    = false
        
        linkButton.addTarget(self, action: Selector("buttonWasPressed:"), forControlEvents: .TouchUpInside)

        return linkButton
    }
    
    // MARK: - IBActions
    @IBAction public func buttonWasPressed(sender: DTLinkButton) {
        if let listener = onUrlClick {
            listener(sender.URL)
        }
    }
}
