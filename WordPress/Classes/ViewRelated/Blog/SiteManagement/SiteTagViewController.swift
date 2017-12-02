import UIKit

final class SiteTagViewController: UITableViewController {
    private let blog: Blog
    private let tag: PostTag
    
    public init(blog: Blog, tag: PostTag) {
        self.blog = blog
        self.tag = tag
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
