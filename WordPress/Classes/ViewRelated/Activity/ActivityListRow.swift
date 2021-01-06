
struct ActivityListRow: ImmuTableRow {
    typealias CellType = ActivityTableViewCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "ActivityTableViewCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    var activity: Activity {
        return formattableActivity.activity
    }
    let action: ImmuTableAction?
    let actionButtonHandler: (UIButton) -> Void

    private let formattableActivity: FormattableActivity

    init(formattableActivity: FormattableActivity,
         action: ImmuTableAction?,
         actionButtonHandler: @escaping (UIButton) -> Void) {
        self.formattableActivity = formattableActivity
        self.action = action
        self.actionButtonHandler = actionButtonHandler
    }

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType
        cell.configureCell(formattableActivity)
        cell.selectionStyle = .none
        cell.actionButtonHandler = actionButtonHandler
    }
}
