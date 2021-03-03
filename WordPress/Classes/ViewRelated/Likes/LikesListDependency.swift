import Foundation
import WordPressKit


class LikesListDependency {

    private let context: NSManagedObjectContext

    lazy var postService: PostService = {
        PostService(managedObjectContext: self.context)
    }()

    lazy var commentService: CommentService = {
        CommentService(managedObjectContext: self.context)
    }()

    init(context: NSManagedObjectContext = ContextManager.shared.mainContext) {
        self.context = context
    }

}
