import UIKit

/// Encapsulates data for a row in an `OptionsTableView`.
///
struct OptionsTableViewOption: Equatable {
    let image: UIImage?
    let title: NSAttributedString
    let accessibilityLabel: String?

    // MARK: - Equatable

    static func ==(lhs: OptionsTableViewOption, rhs: OptionsTableViewOption) -> Bool {
        return lhs.title == rhs.title
    }
}

class OptionsTableViewController: UITableViewController {
    private static let rowHeight: CGFloat = 44.0

    typealias OnSelectHandler = (_ selected: Int) -> Void

    var options = [OptionsTableViewOption]()

    @objc var onSelect: OnSelectHandler?

    @objc var cellBackgroundColor: UIColor = .white {
        didSet {
            tableView.backgroundColor = cellBackgroundColor
            tableView?.reloadData()
        }
    }

    @objc var cellSelectedBackgroundColor: UIColor = .lightGray

    @objc var cellDeselectedTintColor: UIColor? {
        didSet {
            tableView?.reloadData()
        }
    }

    init(options: [OptionsTableViewOption]) {
        self.options = options
        super.init(style: .plain)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = cellBackgroundColor

        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(OptionsTableViewCell.self, forCellReuseIdentifier: OptionsTableViewCell.reuseIdentifier)

        preferredContentSize = CGSize(width: 0, height: min(CGFloat(options.count), 7.5) * OptionsTableViewController.rowHeight)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func selectRow(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)

        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
    }
}

extension OptionsTableViewController {

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        cell.accessoryType = .none
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        cell.accessoryType = .checkmark
        onSelect?(indexPath.row)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = cellBackgroundColor

        let selectedView = UIView()
        selectedView.backgroundColor = cellSelectedBackgroundColor
        cell.selectedBackgroundView = selectedView
    }
}

extension OptionsTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseCell = tableView.dequeueReusableCell(withIdentifier: OptionsTableViewCell.reuseIdentifier, for: indexPath) as! OptionsTableViewCell

        let option = options[indexPath.row]
        reuseCell.textLabel?.attributedText = option.title
        reuseCell.imageView?.image = option.image

        reuseCell.deselectedTintColor = cellDeselectedTintColor
        reuseCell.accessibilityLabel = option.accessibilityLabel

        let isSelected = indexPath.row == tableView.indexPathForSelectedRow?.row
        reuseCell.isSelected = isSelected

        return reuseCell
    }
}

class OptionsTableViewCell: UITableViewCell {
    @objc static let reuseIdentifier = "OptionCell"

    @objc var deselectedTintColor: UIColor?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Our Gridicons look slightly better if shifted down one px
        imageView?.frame.origin.y += 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Icons should always appear deselected
        imageView?.tintColor = deselectedTintColor
        accessoryType = selected ? .checkmark : .none
    }
}
