import UIKit

class OptionsTableView: UITableView {

    var options = [NSAttributedString]()

    var onSelect: ((_ selected: Int) -> Void)?

    init(frame: CGRect, options: [NSAttributedString]) {
        self.options = options
        super.init(frame: frame, style: .plain)
        self.delegate = self
        self.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension OptionsTableView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        cell.accessoryType = .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        cell.accessoryType = .checkmark
        onSelect?(indexPath.row)
    }
}

extension OptionsTableView: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseCell = self.dequeueReusableCell(withIdentifier: "OptionCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "OptionCell")
        reuseCell.textLabel?.attributedText = options[indexPath.row]
        reuseCell.accessoryType = indexPath.row == super.indexPathForSelectedRow?.row ? .checkmark : .none
        reuseCell.isSelected = indexPath.row == super.indexPathForSelectedRow?.row
        return reuseCell
    }
}
