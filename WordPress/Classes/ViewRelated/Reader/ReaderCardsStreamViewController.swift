import Foundation

class ReaderCardsStreamViewController: ReaderStreamViewController {
    class func controller() -> ReaderCardsStreamViewController {
        let controller = ReaderCardsStreamViewController()
        return controller
    }

    override func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderCard.classNameWithoutNamespaces())
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest(ascending: true)
        return fetchRequest
    }

    override func predicateForFetchRequest() -> NSPredicate {
        return NSPredicate(format: "post == NULL OR post != null")
    }
}
