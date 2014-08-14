import Foundation


@objc public class NoteBlockCommentTableViewCell : NoteBlockTextTableViewCell
{
    public typealias EventHandler = (() -> Void)
    
    public var onLikeClick:  EventHandler?
    public var onSpamClick:  EventHandler?
    public var onTrashClick: EventHandler?
    public var onMoreClick:  EventHandler?
    
    @IBAction public func likeWasPressed(sender: AnyObject) {
        hitEventHandler(onLikeClick)
    }
    
    @IBAction public func spamWasPressed(sender: AnyObject) {
        hitEventHandler(onSpamClick)
    }
    
    @IBAction public func trashWasPressed(sender: AnyObject) {
        hitEventHandler(onTrashClick)
    }
    
    @IBAction public func moreWasPressed(sender: AnyObject) {
        hitEventHandler(onMoreClick)
    }
    
    private func hitEventHandler(handler: EventHandler?) {
        if let listener = handler {
            listener()
        }
    }
}
