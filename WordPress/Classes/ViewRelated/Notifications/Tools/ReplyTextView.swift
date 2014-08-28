import Foundation


@objc public class ReplyTextView : UIView, UITextViewDelegate
{
    // MARK: - Initializers
    public convenience init(width: Int) {
        let theFrame = CGRect(x: 0, y: 0, width: width, height: 0)
        self.init(frame: theFrame)
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    // MARK: - Public Properties
    public var placeholder: String! {
        didSet {
            placeholderLabel.text       = placeholder
        }
    }

    public var replyText: String! {
        didSet {
            replyButton.setTitle(replyText, forState: .Normal)
        }
    }
    
    
    // MARK: - Public Helpers
    public func alignAtBottomOfSuperview() {
        if let theSuperview = superview {
            frame.origin.y = CGRectGetMaxY(theSuperview.bounds) - bounds.height
        }
    }
    
    
    // MARK: - UITextViewDelegate
    public func textViewDidChange(textView: UITextView!) {
        placeholderLabel.hidden = !textView.text.isEmpty
        updateTextViewSize()
        scrollToCaretInTextView()
    }
    
    
    // MARK: - View Methods
    public override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        endEditing(true)
        return textView.resignFirstResponder()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame.size.width = self.bounds.width
    }
    
    // MARK: - Private Helpers
    private func updateTextViewSize() {
        let textSize        = textView.contentSize
        
        let oldHeight       = frame.height
        let textHeight      = ceil(textSize.height) + textViewPadding.bottom + textViewPadding.top
        let newHeight       = min(max(textHeight, textViewMinHeight), textViewMaxHeight)
        
        if oldHeight == newHeight {
            return
        }
        
        frame.size.height   = newHeight
        frame.origin.y      += oldHeight - newHeight
    }
    
    private func scrollToCaretInTextView() {
        textView.layoutIfNeeded()
        
        var caretRect           = textView.caretRectForPosition(textView.selectedTextRange.start)
        caretRect.size.height   += textView.textContainerInset.bottom + textViewPadding.bottom
        
        caretRect               = CGRectIntegral(caretRect)
        
        textView.scrollRectToVisible(caretRect, animated: false)
    }
    
    private func setupView() {
        self.frame.size.height          = textViewMinHeight
        
        // Load the nib + add its container view
        bundle = NSBundle.mainBundle().loadNibNamed("ReplyTextView", owner: self, options: nil)
        addSubview(containerView)
        
        // We want this view to stick at the bottom
        contentMode                     = .BottomLeft
        autoresizingMask                = .FlexibleWidth | .FlexibleTopMargin
        containerView.autoresizingMask  = .FlexibleWidth | .FlexibleHeight
        
        // Setup the TextView
        textView.delegate               = self
        textView.scrollsToTop           = false
        textView.contentInset           = UIEdgeInsetsZero
        textView.font                   = WPStyleGuide.Comments.Fonts.replyText
        textView.textColor              = WPStyleGuide.Comments.Colors.replyText
        
        // Placeholder
        placeholderLabel.font           = WPStyleGuide.Comments.Fonts.replyText
        placeholderLabel.textColor      = WPStyleGuide.Comments.Colors.replySeparator
        
        // Reply
        replyButton.titleLabel.font     = WPStyleGuide.Comments.Fonts.replyButton
        replyButton.setTitleColor(WPStyleGuide.Comments.Colors.replyDisabled, forState: .Disabled)
        replyButton.setTitleColor(WPStyleGuide.Comments.Colors.replyEnabled,  forState: .Normal)
        
        // Background
        layoutView.backgroundColor      = WPStyleGuide.Comments.Colors.replyBackground
    }
    
    // MARK: - Constants
    private let textViewPadding:            UIEdgeInsets    = UIEdgeInsets(top: 2, left: 0, bottom: 1, right: 0)
    private let textViewMaxHeight:          CGFloat         = 77   // Fits 3 lines onscreen
    private let textViewMinHeight:          CGFloat         = 44
    private var bundle:                     NSArray?
    
    // MARK: - IBOutlets
    @IBOutlet public var textView:         UITextView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var replyButton:      UIButton!
    @IBOutlet private var layoutView:       UIView!
    @IBOutlet private var containerView:    UIView!
}


//  NOTE:
//  =====
//  ReplyBezierView is a helper class, used to render the TextField bubble
//
public class ReplyBezierView : UIView {
    
    public var fieldBackgroundColor: UIColor = WPStyleGuide.Comments.Colors.replyBackground {
        didSet {
            setNeedsDisplay()
        }
    }
    public var separatorColor: UIColor = WPStyleGuide.Comments.Colors.replySeparator {
        didSet {
            setNeedsDisplay()
        }
    }
    public var topLineHeight: CGFloat = 0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    public var cornerRadius: CGFloat = 5 {
        didSet {
            setNeedsDisplay()
        }
    }
    public var insets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 54) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Initializers
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    private func setupView() {
        // Make sure this is re-drawn on rotation events
        layer.needsDisplayOnBoundsChange    = true
    }
    
    // MARK: - View Methods
    public override func drawRect(rect: CGRect) {
        // Draw the background, while clipping a rounded rect with the given insets
        var bezierRect                      = bounds
        bezierRect.origin.x                 += insets.left
        bezierRect.origin.y                 += insets.top
        bezierRect.size.height              -= insets.top + insets.bottom
        bezierRect.size.width               -= insets.left + insets.right
        let bezier                          = UIBezierPath(roundedRect: bezierRect, cornerRadius: cornerRadius)
        let outer                           = UIBezierPath(rect: bounds)
        
        separatorColor.set()
        bezier.stroke()
        
        fieldBackgroundColor.set()
        bezier.appendPath(outer)
        bezier.usesEvenOddFillRule = true
        bezier.fill()
        
        // Draw the top separator line
        separatorColor.set()
        let topLineFrame = CGRect(x: 0, y: 0, width: bounds.width, height: topLineHeight)
        UIRectFill(topLineFrame)
    }
}
