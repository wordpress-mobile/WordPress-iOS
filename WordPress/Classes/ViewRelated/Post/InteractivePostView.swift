import Foundation

protocol InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate)
    func setActionSheetDelegate(_ delegate: PostActionSheetDelegate)
}
