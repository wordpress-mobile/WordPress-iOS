import Foundation
import WordPressShared

@objc open class ReaderPostCardCell: UITableViewCell
{
    // Helper Views
    @IBOutlet fileprivate weak var borderedView: UIView!
    @IBOutlet fileprivate weak var card: ReaderCard!

    open var delegate: ReaderCardDelegate? {
        get {
            return card.delegate
        }
        set {
            card.delegate = newValue
        }
    }


    open var  post: ReaderPost? {
        get {
            return card.readerPost
        }
        set {
            card.readerPost = newValue
        }
    }


    open var hidesFollowButton: Bool {
        get {
            return card.hidesFollowButton
        }
        set {
            card.hidesFollowButton = newValue
        }
    }


    open var enableLoggedInFeatures: Bool {
        get {
            return card.enableLoggedInFeatures
        }
        set {
            card.enableLoggedInFeatures = newValue
        }
    }


    open var headerBlogButtonIsEnabled: Bool {
        get {
            return card.headerButtonIsEnabled
        }
        set {
            card.headerButtonIsEnabled = newValue
        }
    }


    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }


    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let previouslyHighlighted = self.isHighlighted
        super.setHighlighted(highlighted, animated: animated)

        if previouslyHighlighted == highlighted {
            return
        }
        applyHighlightedEffect(highlighted, animated: animated)
    }


    // MARK: - Lifecycle Methods
    open override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }


    // MARK: - Configuration


    /// Applies the default styles to the cell's subviews
    ///
    fileprivate func applyStyles() {
        contentView.backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = 1.0
    }


    open func configureCell(_ post: ReaderPost) {
        card.readerPost = post
    }


    fileprivate func applyHighlightedEffect(_ highlighted: Bool, animated: Bool) {
        func updateBorder() {
            self.borderedView.layer.borderColor = highlighted ? WPStyleGuide.readerCardCellHighlightedBorderColor().cgColor : WPStyleGuide.readerCardCellBorderColor().cgColor
        }
        guard animated else {
            updateBorder()
            return
        }
        UIView.animate(withDuration: 0.25,
            delay: 0,
            options: UIViewAnimationOptions(),
            animations: updateBorder,
            completion: nil)
    }

}
