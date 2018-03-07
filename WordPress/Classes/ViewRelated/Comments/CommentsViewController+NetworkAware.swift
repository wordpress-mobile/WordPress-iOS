import UIKit

extension CommentsViewController: NetworkAwareUI {
    public func contentIsEmpty() -> Bool {
        return tableViewHandler.resultsController.isEmpty()
    }
}
