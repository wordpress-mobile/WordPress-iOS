import Foundation
import CoreData

/// Pages can have a parent and children. Given "Page A", all pages are eligible to become "Page A"'s parent except "Page A"'s children pages.
///
/// This class doesn't change a page's parent, rather it provides an API to access a page's eligible parents.
@objc class ParentPagesController: NSObject {

    // MARK: - Dependencies

    private let managedObjectContext: NSManagedObjectContext

    // MARK: - Properties

    private let blog: Blog
    private var pages = [Page]()

    // MARK: - Init

    @objc init(blog: Blog, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext) {
        self.blog = blog
        self.managedObjectContext = managedObjectContext
        super.init()
        self.refreshPages()
    }

    // MARK: - Fetching Parent Posts

    /// Returns the page's parent.
    @objc func selectedParent(forPage page: Page) -> Page? {
        guard let page = pages.first(where: { $0.postID == page.parentID }) else { return nil }
        return page
    }

    /// Returns a list of pages that can be selected as a parent for the provided page.
    /// - Parameter page: The child page that's changing their parent.
    /// - Returns: List of pages eligible to become a parent.
    @objc func availableParentsForEditing(forPage page: Page) -> [Page] {
        guard let index = pages.firstIndex(of: page) else { return pages }
        return pages.remove(from: index)
    }

    /// Refreshes the underlying pages.
    ///
    /// Call this method whenever a new page is added, or an existing one is updated.
    @objc func refreshPages() {
        do {
            let result = try self.managedObjectContext.fetch(fetchRequest(blog: blog))
            let pages = result.setHomePageFirst().hierarchySort()
            self.pages = pages
        } catch _ {
            self.pages = []
        }
    }

    // MARK: - Helpers

    private func fetchRequest(blog: Blog) -> NSFetchRequest<Page> {
        let fetchRequest = NSFetchRequest<Page>(entityName: String(describing: Page.self))
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "blog = %@ AND revision = nil", blog),
            PostListFilter.publishedFilter().predicateForFetchRequest
        ])
        return fetchRequest
    }
}
