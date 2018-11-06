import UIKit

/// Generics-based implementation of the UITableViewDataSource and UITableViewDelegate protocol. It will dispatch a notification when an item is selected
final class SiteCreationDataCoordinator<Model, Cell>: NSObject, UITableViewDataSource, UITableViewDelegate where Cell: ModelSettableCell, Cell: UITableViewCell, Model == Cell.DataType {
    private let data: [Model]
    private let selection: (Model) -> Void

    init(data: [Model], cellType: Cell.Type, selection: @escaping (Model) -> Void) {
        self.data = data
        self.selection = selection
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if var cell = tableView.dequeueReusableCell(withIdentifier: Cell.cellReuseIdentifier(), for: indexPath) as? Cell {
            let dataItem = data[indexPath.row]
            cell.model = dataItem

            return cell
        }

        return Cell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedModel = data[indexPath.row]
        selection(selectedModel)
    }
}
