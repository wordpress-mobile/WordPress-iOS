import Foundation
import CoreData
import Combine

public final class ManagedObjectsObserver<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    @Published private(set) public var objects: [T] = []

    private let controller: NSFetchedResultsController<T>

    public convenience init(
        predicate: NSPredicate,
        sortDescriptors: [SortDescriptor<T>],
        context: NSManagedObjectContext
    ) {
        let request = NSFetchRequest<T>(entityName: T.entity().name ?? "")
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors.map(NSSortDescriptor.init)
        self.init(request: request, context: context)
    }

    public init(
        request: NSFetchRequest<T>,
        context: NSManagedObjectContext,
        cacheName: String? = nil
    ) {
        self.controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: cacheName)
        super.init()

        try? controller.performFetch()
        objects = controller.fetchedObjects ?? []

        controller.delegate = self
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objects = self.controller.fetchedObjects ?? []
    }
}
