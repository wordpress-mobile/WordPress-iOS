// A table view handler offset by 1 (for Add a Topic in Reader Tags)
class OffsetTableViewHandler: WPTableViewHandler {

    func object(at indexPath: IndexPath) -> NSFetchRequestResult? {
        guard let indexPath = adjusted(indexPath: indexPath) else {
            return nil
        }
        return resultsController.object(at: indexPath)
    }

    func adjusted(indexPath: IndexPath) -> IndexPath? {
        guard indexPath.row > 0 else {
            return nil
        }
        return IndexPath(row: indexPath.row - 1, section: indexPath.section)
    }

    func adjustedToTable(indexPath: IndexPath) -> IndexPath {
        let newIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        return newIndexPath
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section) + 1
    }

    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                             didChange anObject: Any,
                             at indexPath: IndexPath?,
                             for type: NSFetchedResultsChangeType,
                             newIndexPath: IndexPath?) {

        let oldIndexPath = indexPath.map {
            adjustedToTable(indexPath: $0)
        } ?? nil

        let newPath = newIndexPath.map {
            adjustedToTable(indexPath: $0)
        } ?? nil

        super.controller(controller, didChange: anObject, at: oldIndexPath, for: type, newIndexPath: newPath)
    }
}
