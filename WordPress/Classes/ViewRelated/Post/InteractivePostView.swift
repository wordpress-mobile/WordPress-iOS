import Foundation

@objc protocol InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate)
    @objc optional func setActionSheetDelegate(_ delegate: PostActionSheetDelegate)
}
