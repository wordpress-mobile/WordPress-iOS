import Foundation
import WordPressShared


/// Renders a table with the following structure:
///     Section | Row   ContentView
///     0           1   [Text]  [Switch]    < Shows / Hides Section 1
///     1           0   [Text]  [Text]
///     1           1   [Picker]
///
open class SettingsPickerViewController: UITableViewController {
    /// Indicates whether a Switch row should be rendered on top, allowing the user to Enable / Disable the picker
    @objc open var switchVisible = true

    /// Specifies the Switch value, to be displayed on the first row (granted that `switchVisible` is set to true)
    @objc open var switchOn = false

    /// Text to be displayed by the first row's Switch
    @objc open var switchText: String!

    /// Text to be displayed in the "Currently Selected value" row
    @objc open var selectionText: String!

    /// Indicates the format to be used in the "Currently Selected Value" row
    @objc open var selectionFormat: String?

    /// Hint Text, to be displayed on top of the Picker
    @objc open var pickerHint: String?

    /// String format, to be applied over the Picker Rows
    @objc open var pickerFormat: String?

    /// Currently selected value.
    open var pickerSelectedValue: Int!

    /// Picker's minimum value.
    open var pickerMinimumValue: Int!

    /// Picker's maximum value.
    open var pickerMaximumValue: Int!

    /// Closure to be executed whenever the Switch / Picker is updated
    @objc open var onChange : ((_ enabled: Bool, _ newValue: Int) -> ())?



    // MARK: - View Lifecycle
    open override func viewDidLoad() {
        assert(selectionText     != nil)
        assert(pickerSelectedValue != nil)
        assert(pickerMinimumValue  != nil)
        assert(pickerMaximumValue  != nil)

        super.viewDidLoad()
        setupTableView()
    }



    // MARK: - Setup Helpers
    fileprivate func setupTableView() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
    }



    // MARK: - UITableViewDataSoutce Methods
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = cellForRow(row, tableView: tableView)

        switch row {
        case .Switch:
            configureSwitchCell(cell as! SwitchTableViewCell)
        case .Value1:
            configureTextCell(cell as! WPTableViewCell)
        case .Picker:
            configurePickerCell(cell as! PickerTableViewCell)
        }

        return cell
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section != sectionWithFooter || pickerHint == nil {
            return nil
        }
        return pickerHint!
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }


    // MARK: - Cell Setup Helpers
    fileprivate func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section][indexPath.row]
    }

    fileprivate func cellForRow(_ row: Row, tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: row.rawValue) {
            return cell
        }

        switch row {
        case .Value1:
            return WPTableViewCell(style: .value1, reuseIdentifier: row.rawValue)
        case .Switch:
            return SwitchTableViewCell(style: .default, reuseIdentifier: row.rawValue)
        case .Picker:
            return PickerTableViewCell(style: .default, reuseIdentifier: row.rawValue)
        }
    }

    fileprivate func configureSwitchCell(_ cell: SwitchTableViewCell) {
        cell.selectionStyle         = .none
        cell.name                   = switchText
        cell.on                     = switchOn
        cell.onChange               = { [weak self] in
            self?.switchDidChange($0)
        }
    }

    fileprivate func configureTextCell(_ cell: WPTableViewCell) {
        let format                  = selectionFormat ?? "%d"

        cell.selectionStyle         = .none
        cell.textLabel?.text        = selectionText
        cell.detailTextLabel?.text  = String(format: format, pickerSelectedValue)

        WPStyleGuide.configureTableViewCell(cell)
    }

    fileprivate func configurePickerCell(_ cell: PickerTableViewCell) {
        cell.selectionStyle         = .none
        cell.minimumValue           = pickerMinimumValue!
        cell.maximumValue           = max(pickerSelectedValue, pickerMaximumValue)
        cell.selectedValue          = pickerSelectedValue
        cell.textFormat             = pickerFormat
        cell.onChange               = { [weak self] in
            self?.pickerDidChange($0)
        }
    }



    // MARK: - Button Handlers Properties
    fileprivate func switchDidChange(_ newValue: Bool) {
        switchOn = newValue

        // Show / Hide the Picker Section
        let pickerSectionIndexSet = IndexSet(integer: pickerSection)

        if newValue {
            tableView.insertSections(pickerSectionIndexSet, with: .fade)
        } else {
            tableView.deleteSections(pickerSectionIndexSet, with: .fade)
        }

        // Hit the Callback
        onChange?(switchOn, pickerSelectedValue)
    }

    fileprivate func pickerDidChange(_ newValue: Int) {
        pickerSelectedValue = newValue

        // Refresh the 'Current Value' row
        if let cell = tableView.cellForRow(at: selectedValueIndexPath) as? WPTableViewCell {
            configureTextCell(cell)
        }

        // Hit the Callback
        onChange?(switchOn, pickerSelectedValue)
    }



    // MARK: - Nested Enums
    fileprivate enum Row: String {
        case Value1 = "Value1"
        case Switch = "SwitchCell"
        case Picker = "Picker"
    }

    // MARK: - Computed Properties
    fileprivate var sections: [[Row]] {
        var sections = [[Row]]()

        if switchVisible {
            sections.append([.Switch])
        }

        if switchOn || !switchVisible {
            sections.append([.Value1, .Picker])
        }

        return sections
    }

    fileprivate var pickerSection: Int {
        return switchVisible ? 1 : 0
    }

    fileprivate var selectedValueIndexPath: IndexPath {
        return IndexPath(row: 0, section: pickerSection)
    }

    // MARK: - Private Constants
    fileprivate let estimatedRowHeight  = CGFloat(300)
    fileprivate let sectionWithFooter   = 0
}
