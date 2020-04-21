import Foundation
import UIKit


/// Wrangles attachment layout and exclusion paths for the specified UITextView.
///
@objc open class WPTextAttachmentManager: NSObject {
    @objc open var attachments = [WPTextAttachment]()
    var attachmentViews = [WPTextAttachment: WPTextAttachmentView]()
    @objc open weak var delegate: WPTextAttachmentManagerDelegate?
    @objc fileprivate(set) open weak var textView: UITextView?
    @objc let layoutManager: NSLayoutManager
    @objc let infiniteFrame = CGRect(x: CGFloat.infinity, y: CGFloat.infinity, width: 0.0, height: 0.0)


    /// Designaged initializer.
    ///
    /// - Parameters:
    ///     - textView: The UITextView to manage attachment layout.
    ///     - delegate: The delegate who will provide the UIViews used as content represented by WPTextAttachments in the UITextView's NSAttributedString.
    ///
    @objc public init(textView: UITextView, delegate: WPTextAttachmentManagerDelegate) {
        self.textView = textView
        self.delegate = delegate
        self.layoutManager = textView.layoutManager

        super.init()

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
    @objc open func viewForAttachment(_ attachment: WPTextAttachment) -> UIView? {
        return attachmentViews[attachment]?.view
    }


    /// Updates the layout of any custom attachment views.  Call this method after
    /// making changes to the alignment or size of an attachment's custom view,
    /// or after updating an attachment's `image` property.
    ///
    @objc open func layoutAttachmentViews() {
        // Guard for paranoia
        guard let textStorage = layoutManager.textStorage else {
            print("Unable to layout attachment views. No NSTextStorage.")
            return
        }

        guard let textView = self.textView else {
            print("Unable to layout attachment views. No UITextView.")
            return
        }

        // Gather up all of the attachments
        var attachmentsAndRanges = [(WPTextAttachment, NSRange)]()
        textStorage.enumerateAttribute(.attachment,
            in: NSMakeRange(0, textStorage.length),
            options: [],
            using: { (object: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                guard let attachment = object as? WPTextAttachment else {
                    return
                }

                attachmentsAndRanges.append((attachment, range))
        })

        guard attachmentsAndRanges.count > 0 else {
            return
        }

        // Invalidate the layout wherever attachments are
        let combinedRange = attachmentsAndRanges.reduce(NSRange(location: 0, length: Int.max)) {
            $0.union($1.1)
        }

        layoutManager.invalidateLayout(forCharacterRange: combinedRange, actualCharacterRange: nil)
        layoutManager.ensureLayout(for: textView.textContainer)

        // Make sure attachments are correctly laid out.
        attachmentsAndRanges.forEach { (attachment, range) in

            guard let attachmentView = attachmentViews[attachment] else {
                return
            }

            let frame = textView.frameForTextInRange(range)
            if frame == infiniteFrame {
                return
            }

            attachmentView.view.frame = frame
        }
    }

    /// Called initially during the initial set up of the manager.
    //  Should be called whenever the UITextView's attributedText property changes.
    /// After resetting the attachment manager, this method loops over any
    /// WPTextAttachments found in textStorage and asks the delegate for a
    /// custom view for the attachment.
    ///
    @objc func enumerateAttachments() {
        resetAttachmentManager()

        // Safety new
        guard let textStorage = layoutManager.textStorage else {
            return
        }

        layoutManager.textStorage?.enumerateAttribute(.attachment,
            in: NSMakeRange(0, textStorage.length),
            options: [],
            using: { (object: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                guard let attachment = object as? WPTextAttachment else {
                    return
                }
                self.attachments.append(attachment)

                if let view = self.delegate?.attachmentManager(self, viewForAttachment: attachment) {
                    self.attachmentViews[attachment] = WPTextAttachmentView(view: view, identifier: attachment.identifier, exclusionPath: nil)
                    self.textView?.addSubview(view)
                }
        })

        layoutAttachmentViews()
    }


    /// Resets the attachment manager. Any custom views for WPTextAttachments are
    /// removed from the UITextView, their exclusion paths are removed from
    /// textStorage.
    ///
    fileprivate func resetAttachmentManager() {
        for (_, attachmentView) in attachmentViews {
            attachmentView.view.removeFromSuperview()
        }
        attachmentViews.removeAll()
        attachments.removeAll()
    }
}


/// A UITextView does not register as delegate to its NSLayoutManager so the
/// WPTextAttachmentManager does in order to be notified of any changes to the size
/// of the UITextView's textContainer.
///
extension WPTextAttachmentManager: NSLayoutManagerDelegate {
    /// When the size of an NSTextContainer managed by the NSLayoutManager changes
    /// this method updates the size of any custom views for WPTextAttachments,
    /// then lays out the attachment views.
    ///
    public func layoutManager(_ layoutManager: NSLayoutManager, textContainer: NSTextContainer, didChangeGeometryFrom oldSize: CGSize) {
        layoutAttachmentViews()
    }
}


/// A WPTextAttachmentManagerDelegate provides custom views for WPTextAttachments to
/// its WPTextAttachmentManager.
///
@objc public protocol WPTextAttachmentManagerDelegate: NSObjectProtocol {
    /// Delegates must implement this method and return either a UIView or nil for
    /// the specified WPTextAttachment.
    ///
    /// - Parameters:
    ///     - attachmentManager: The WPTextAttachmentManager.
    ///     - attachment: The WPTextAttachment
    ///
    /// - Returns: A UIView to represent the specified WPTextAttachment or nil.
    ///
    func attachmentManager(_ attachmentManager: WPTextAttachmentManager, viewForAttachment attachment: WPTextAttachment) -> UIView?
}


/// A convenience class for grouping a custom view with its attachment and
/// exclusion path.
///
class WPTextAttachmentView {
    var view: UIView
    var identifier: String
    var exclusionPath: UIBezierPath?

    init(view: UIView, identifier: String, exclusionPath: UIBezierPath?) {
        self.view = view
        self.identifier = identifier
        self.exclusionPath = exclusionPath
    }
}
