import UIKit

final class SiteTagViewController: UITableViewController {
    private let blog: Blog
    private let tagsService: PostTagService
    private let tag: PostTag
    
    public init(blog: Blog, tag: PostTag, tagsService: PostTagService) {
        self.blog = blog
        self.tag = tag
        self.tagsService = tagsService
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
