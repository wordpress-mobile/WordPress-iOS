import UIKit
import XCTest

@testable import WordPress

class PostListTableViewHandlerTests: XCTestCase {

    func testReturnAResultsControllerForViewingAndOtherWhenSearching() {
        let postListHandlerMock = PostListHandlerMock()
        let postListHandler = PostListTableViewHandler()
        postListHandler.delegate = postListHandlerMock
        let defaultResultsController = postListHandler.resultsController

        postListHandler.isSearching = true

        XCTAssertNotEqual(defaultResultsController, postListHandler.resultsController)
    }
}

class PostListHandlerMock: NSObject, WPTableViewHandlerDelegate {
    func managedObjectContext() -> NSManagedObjectContext {
        return setUpInMemoryManagedObjectContext()
    }

    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let a = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Post.self))
        a.sortDescriptors = [NSSortDescriptor(key: BasePost.statusKeyPath, ascending: true)]
        return a
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) { }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { }

    private func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }

        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }
}
