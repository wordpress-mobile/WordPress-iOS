final class SiteCreationContentDelegate<Model>: NSObject, UITableViewDelegate {
    private let data: [Model]

    init(data: [Model]) {
        self.data = data
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedModel = data[indexPath.row]
        print("===== selected model ===", selectedModel)
    }
}
