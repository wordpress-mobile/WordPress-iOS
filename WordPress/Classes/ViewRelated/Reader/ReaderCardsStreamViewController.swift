import Foundation

class ReaderCardsStreamViewController: ReaderStreamViewController {
    // MARK: - TableView Related

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let posts = content.content as? [ReaderCard], let cardPost = posts[indexPath.row].post {
            return cell(for: cardPost, at: indexPath)
        } else {
            return UITableViewCell()
        }
    }

    // MARK: - TableViewHandler

    override func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ReaderCard.classNameWithoutNamespaces())
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest(ascending: true)
        return fetchRequest
    }

    override func predicateForFetchRequest() -> NSPredicate {
        return NSPredicate(format: "post == NULL OR post != null")
    }

    // MARK: - Init Methods

    class func controller() -> ReaderCardsStreamViewController {
        let controller = ReaderCardsStreamViewController()
        return controller
    }
}
