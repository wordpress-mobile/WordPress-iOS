import UIKit
import Gridicons

class PostCompactCell: UITableViewCell, ConfigurablePostView {
    func configure(with post: Post) {

    }
}

extension PostCompactCell: InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        
    }
}
