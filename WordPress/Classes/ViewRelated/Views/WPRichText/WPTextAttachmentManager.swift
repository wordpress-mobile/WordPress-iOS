import Foundation
import UIKit


/// Wrangles attachment layout and exclusion paths for the specified UITextView.
///
@objc public class WPTextAttachmentManager : NSObject
{
    private let attributeAttachmentName = "NSAttachment" // HACK: DTCoreText hijacks NSAttachmentAttributeName.
    private var kvoContext = 0
    private let attributedTextKey = "attributedText"

    public var attachments = [WPTextAttachment]()
    var attachmentViews = [String: WPTextAttachmentView]()
    public var delegate: WPTextAttachmentManagerDelegate?
    private(set) public var textView: UITextView

    var layoutManager: NSLayoutManager {
        return textView.layoutManager
    }


    /// Cleans up KVO
    ///
    deinit {
        textView.removeObserver(self, forKeyPath: attributedTextKey)
    }


    /// Designaged initializer.
    ///
    /// - Parameters:
    ///     - textView: The UITextView to manage attachment layout.
    ///     - delegate: The delegate who will provide the UIViews used as content represented by WPTextAttachments in the UITextView's NSAttributedString.
    ///
    public init(textView: UITextView, delegate: WPTextAttachmentManagerDelegate) {
        self.textView = textView
        self.delegate = delegate

        super.init()

        setupManager()
    }


    /// Watches for changes in the textView's attributedText.
    ///
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context != &kvoContext ||
            keyPath == nil ||
            attributedTextKey != keyPath! ||
            textView != object as? UITextView
        {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }

        enumerateAttachments()
    }


    /// Initial setup.  Should only be called once during init.
    ///
    private func setupManager() {
        textView.addObserver(self, forKeyPath: attributedTextKey, options: .New, context: &kvoContext)
        layoutManager.delegate = self

        enumerateAttachments()
    }


    /// Returns the custom view for the specified WPTextAttachment or nil if not found.
    ///
    /// - Parameters:
    ///     - attachment: The WPTextAttachment
    ///
    /// - Returns: A UIView optional
    ///
    public func viewForAttachment(attachment: WPTextAttachment) -> UIView? {
        return attachmentViews[attachment.identifier]?.view
    }


    /// Returns the custom view for the specified WPTextAttachment or nil if not found.
    ///
    /// - Parameters:
    ///     - view: The view that should be displayed for the attachment
    ///     - attachment: The WPTextAttachment
    ///
    public func assignView(view: UIView, forAttachment attachment: WPTextAttachment) {
        var attachmentView: WPTextAttachmentView

        if let aView = attachmentViews[attachment.identifier] {
            attachmentView = aView
            attachmentView.view.removeFromSuperview()
            attachmentView.view = view
        } else {
            attachmentView = WPTextAttachmentView(view: view, identifier: attachment.identifier, exclusionPath: nil)
            attachmentViews[attachment.identifier] = attachmentView
        }

        textView.addSubview(view)

        resizeViewForAttachment(attachment, toFitSize: textView.textContainer.size)

        layoutAttachmentViews()
    }


    /// Updates the layout of any custom attachment views.  Call this method after
    /// making changes to the alignment or size of an attachment's custom view,
    /// or after updating an attachment's `image` property.
    ///
    public func layoutAttachmentViews() {
        // Guard for paranoia
        guard let textStorage = layoutManager.textStorage else {
            print("Unable to layout attachment views. No NSTextStorage.")
            return
        }

        // Remove any existing attachment exclusion paths and ensure layout.
        // This ensures previous (soon to be invalid) exclusion paths do not
        // conflict with the new layout.
        var exclusionPaths = textView.textContainer.exclusionPaths
        for (_, attachmentView) in attachmentViews {
            guard let exclusionPath = attachmentView.exclusionPath else {
                continue
            }
            if let index = exclusionPaths.indexOf(exclusionPath) {
                exclusionPaths.removeAtIndex(index)
            }
        }

        textView.textContainer.exclusionPaths = exclusionPaths
        layoutManager.ensureLayoutForTextContainer(textView.textContainer)

        // Now do the update.
        textStorage.enumerateAttribute(attributeAttachmentName,
            inRange: NSMakeRange(0, textStorage.length),
            options: [],
            usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                guard let attachment = object as? WPTextAttachment else {
                    return
                }
                layoutAttachmentViewForAttachment(attachment, atRange: range)
        })
    }


    /// Updates the layout of the attachment view for the specified attachment by
    /// creating a new exclusion path for the view based on the location of the
    /// specified attachment, and the frame and alignmnent of the view.
    ///
    /// - Parameters:
    ///     - attachment: The WPTextAttachment
    ///     - range: The range of the WPTextAttachment in the textView's NSTextStorage
    ///
    private func layoutAttachmentViewForAttachment(attachment: WPTextAttachment, atRange range: NSRange) {
        guard let attachmentView = attachmentViews[attachment.identifier] else {
            return
        }

        var exclusionPaths = textView.textContainer.exclusionPaths

        let attachmentFrame = frameForAttachmentView(attachmentView, forAttachment: attachment, atRange: range)

        var exclusionFrame = attachmentFrame
        if attachment.align == .None {
            exclusionFrame = CGRectMake(0.0, attachmentFrame.minY, textView.frame.width, attachmentFrame.height)
        }
        exclusionFrame.origin.y -= textView.textContainerInset.top

        let newExclusionPath = UIBezierPath(rect: exclusionFrame)
        exclusionPaths.append(newExclusionPath)

        attachmentView.exclusionPath = newExclusionPath
        attachmentView.view.frame = attachmentFrame

        textView.textContainer.exclusionPaths = exclusionPaths

        // Always ensure layout after updating an individual exclusion path so
        // subsequent attachments are in their proper location.
        layoutManager.ensureLayoutForTextContainer(textView.textContainer)
    }


    /// Computes the frame for an attachment's custom view based on alignment
    /// and the size of the attachment.  Attachments with a maxSize of CGSizeZero
    /// will scale to match the current width of the textContainer. Attachments
    /// with a maxSize greater than CGSizeZero will never scale up, but may be
    /// scaled down to match the width of the textContainer.
    ///
    /// - Parameters:
    ///     - attachmentView: The WPTextAttachmentView in question.
    ///     - attachment: The WPTextAttachment
    ///     - range: The range of the WPTextAttachment in the textView's NSTextStorage
    ///
    /// - Returns: The frame for the specified custom attachment view.
    ///
    private func frameForAttachmentView(attachmentView: WPTextAttachmentView, forAttachment attachment: WPTextAttachment, atRange range: NSRange) -> CGRect {
        let glyphRange = layoutManager.glyphRangeForCharacterRange(range, actualCharacterRange: nil)

        // The location of the attachment glyph
        let glyphBoundingRect = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textView.textContainer)
        let lineFragmentRect = layoutManager.lineFragmentRectForGlyphAtIndex(glyphRange.location, effectiveRange: nil)

        // Place on the same line if the attachment glyph is at the beginning of the line fragment, otherwise the next line.
        var y = lineFragmentRect.minY
        if attachment.align == .None {
            y = glyphBoundingRect.minX == lineFragmentRect.minX ? lineFragmentRect.minY : lineFragmentRect.maxY
        }

        var frame = attachmentView.view.frame

        // TODO: The padding should probably be (lineheight - capheight) / 2.
        let topLinePadding: CGFloat = 4.0

        frame.origin.y = y + textView.textContainerInset.top + topLinePadding

        switch attachment.align {
        case .None :
            frame.origin.x = textView.textContainer.size.width / 2.0 - (attachmentView.view.frame.width / 2.0)
            break

        case .Left :
            frame.origin.x = 0.0
            break

        case .Right :
            frame.origin.x = textView.textContainer.size.width - attachmentView.view.frame.width
            break

        case .Center :
            frame.origin.x = textView.textContainer.size.width / 2.0 - (attachmentView.view.frame.width / 2.0)
            break
        }

        return frame
    }


    /// Resize (if necessary) the custom view for the specified attachment so that
    /// it fits within the width of its textContainer.
    ///
    /// - Parameters:
    ///     - attachment: The WPTextAttachment
    ///     - size: Should be the size of the textContainer
    ///
    private func resizeViewForAttachment(attachment: WPTextAttachment, toFitSize size: CGSize) {
        guard let attachmentView = attachmentViews[attachment.identifier] else {
            return
        }

        let view = attachmentView.view
        let maxSize = attachment.maxSize

        // If max size height or width is zero, make sure the view's size is zero.
        if maxSize.height == 0 || maxSize.width == 0 {
            view.frame.size.width = 0.0
            view.frame.size.height = 0.0
            return
        }

        var width = maxSize.width
        var height = maxSize.height

        // When the width is max, use the maximum available width and whatever
        // height was specified.
        if maxSize.width == CGFloat.max {
            width = size.width

        } else if width > size.width {
            // When width is greater than the available width scale down.
            let ratio = width / height
            width = floor(size.width)
            height = floor(width / ratio)
        }

        view.frame.size.width = width
        view.frame.size.height = height
    }


    /// Called initially during the initial set up of the manager, and whenever
    /// the UITextView's attributedText property changes.
    /// After resetting the attachment manager, this method loops over any
    /// WPTextAttachments found in textStorage and asks the delegate for a
    /// custom view for the attachment.
    ///
    private func enumerateAttachments() {
        resetAttachmentManager()

        // Safety new
        guard let textStorage = layoutManager.textStorage else {
            return
        }

        layoutManager.textStorage?.enumerateAttribute(attributeAttachmentName,
            inRange: NSMakeRange(0, textStorage.length),
            options: [],
            usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                guard let attachment = object as? WPTextAttachment else {
                    return
                }
                attachments.append(attachment)
                attachment.delegate = self

                if let view = delegate?.attachmentManager(self, viewForAttachment: attachment) {
                    attachmentViews[attachment.identifier] = WPTextAttachmentView(view: view, identifier: attachment.identifier, exclusionPath: nil)
                    resizeViewForAttachment(attachment, toFitSize: textView.textContainer.size)
                    textView.addSubview(view)
                }
        })

        layoutAttachmentViews()
    }


    /// Resets the attachment manager. Any custom views for WPTextAttachments are
    /// removed from the UITextView, their exclusion paths are removed from
    /// textStorage.
    ///
    private func resetAttachmentManager() {
        // Clean up any stale exclusion paths
        let textContainer = textView.textContainer
        for (_, attachmentView) in attachmentViews {
            guard let exclusionPath = attachmentView.exclusionPath else {
                continue
            }
            if let index = textContainer.exclusionPaths.indexOf(exclusionPath) {
                textContainer.exclusionPaths.removeAtIndex(index)
            }
        }

        attachmentViews.removeAll()
        attachments.removeAll()
    }
}


extension WPTextAttachmentManager: WPTextAttachmentDelegate
{
    func attachmentMaxSizeDidChange(attachment: WPTextAttachment) {
        resizeViewForAttachment(attachment, toFitSize: textView.textContainer.size)
    }
}


/// A UITextView does not register as delegate to its NSLayoutManager so the
/// WPTextAttachmentManager does in order to be notified of any changes to the size
/// of the UITextView's textContainer.
///
extension WPTextAttachmentManager: NSLayoutManagerDelegate
{
    /// When the size of an NSTextContainer managed by the NSLayoutManager changes
    /// this method updates the size of any custom views for WPTextAttachments,
    /// then lays out the attachment views.
    ///
    public func layoutManager(layoutManager: NSLayoutManager, textContainer: NSTextContainer, didChangeGeometryFromSize oldSize: CGSize) {
        guard let textStorage = layoutManager.textStorage else {
            return
        }

        let newSize = textView.textContainer.size
        layoutManager.textStorage?.enumerateAttribute(attributeAttachmentName,
            inRange: NSMakeRange(0, textStorage.length),
            options: [],
            usingBlock: { (object:AnyObject?, range:NSRange, stop:UnsafeMutablePointer<ObjCBool>) in
                guard let attachment = object as? WPTextAttachment else {
                    return
                }

                resizeViewForAttachment(attachment, toFitSize: newSize)
        })

        layoutAttachmentViews()
    }
}


/// A WPTextAttachmentManagerDelegate provides custom views for WPTextAttachments to
/// its WPTextAttachmentManager.
///
@objc public protocol WPTextAttachmentManagerDelegate: NSObjectProtocol
{
    /// Delegates must implement this method and return either a UIView or nil for
    /// the specified WPTextAttachment.
    ///
    /// - Parameters:
    ///     - attachmentManager: The WPTextAttachmentManager.
    ///     - attachment: The WPTextAttachment
    ///
    /// - Returns: A UIView to represent the specified WPTextAttachment or nil.
    ///
    func attachmentManager(attachmentManager:WPTextAttachmentManager, viewForAttachment attachment:WPTextAttachment) -> UIView?
}


/// A convenience class for grouping a custom view with its attachment and
/// exclusion path.
///
class WPTextAttachmentView {
    var view: UIView
    var identifier: String
    var exclusionPath: UIBezierPath?

    init(view: UIView, identifier:String, exclusionPath: UIBezierPath?) {
        self.view = view
        self.identifier = identifier
        self.exclusionPath = exclusionPath
    }
}
