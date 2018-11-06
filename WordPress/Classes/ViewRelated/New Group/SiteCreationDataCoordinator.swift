import UIKit

final class SiteCreationDataCoordinator<Model, Cell>: NSObject, UITableViewDataSource, UITableViewDelegate where Cell: ModelSettableCell, Cell: UITableViewCell, Model == Cell.DataType {
    private let data: [Model]

    init(data: [Model], cellType: Cell.Type) {
        self.data = data
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
        print("===== selected model ===", selectedModel)
    }
}
