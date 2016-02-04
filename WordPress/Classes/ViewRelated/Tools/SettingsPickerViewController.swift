import Foundation
import WordPressShared


/// Renders a table with the following structure:
///     Section | Row   ContentView
///     0           1   [Text]  [Switch]    < Shows / Hides Section 1
///     1           0   [Text]  [Text]
///     1           1   [Picker]

public class SettingsPickerViewController : UITableViewController
{
    /// Indicates whether a Switch row should be rendered on top, allowing the user to Enable / Disable the picker
    public var switchVisible = true
    
    /// Specifies the Switch value, to be displayed on the first row (granted that `switchVisible` is set to true)
    public var switchOn = false
    
    /// Text to be displayed by the first row's Switch
    public var switchText : String!
    
    /// Text to be displayed in the "Currently Selected value" row
    public var selectionText : String!
    
    /// Indicates the format to be used in the "Currently Selected Value" row
    public var selectionFormat : String?

    /// Hint Text, to be displayed on top of the Picker
    public var pickerHint : String?
    
    /// String format, to be applied over the Picker Rows
    public var pickerFormat : String?
    
    /// Currently selected value.
    public var pickerSelectedValue : Int!
    
    /// Picker's minimum value.
    public var pickerMinimumValue : Int!
    
    /// Picker's maximum value.
    public var pickerMaximumValue : Int!

    /// Closure to be executed whenever the Switch / Picker is updated
    public var onChange : ((enabled : Bool, newValue: Int) -> ())?
    
    
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        assert(selectionText     != nil)
        assert(pickerSelectedValue != nil)
        assert(pickerMinimumValue  != nil)
        assert(pickerMaximumValue  != nil)

        super.viewDidLoad()
        setupTableView()
    }
    
    
    
    // MARK: - Setup Helpers
    private func setupTableView() {
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
        
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    

    
    // MARK: - UITableViewDataSoutce Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
    
    public override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section != sectionWithFooter || pickerHint == nil {
            return 0
        }
        
        return WPTableViewSectionHeaderFooterView.heightForFooter(pickerHint!, width: tableView.bounds.width)
    }
    
    public override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section != sectionWithFooter || pickerHint == nil {
            return nil
        }
        
        let footerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        footerView.title = pickerHint!
        return footerView
    }
    
    
    
    // MARK: - Cell Setup Helpers
    private func rowAtIndexPath(indexPath: NSIndexPath) -> Row {
        return sections[indexPath.section][indexPath.row]
    }
    
    private func cellForRow(row: Row, tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier(row.rawValue) {
            return cell
        }
        
        switch row {
        case .Value1:
            return WPTableViewCell(style: .Value1, reuseIdentifier: row.rawValue)
        case .Switch:
            return SwitchTableViewCell(style: .Default, reuseIdentifier: row.rawValue)
        case .Picker:
            return PickerTableViewCell(style: .Default, reuseIdentifier: row.rawValue)
        }
    }
    
    private func configureSwitchCell(cell: SwitchTableViewCell) {
        cell.selectionStyle         = .None
        cell.name                   = switchText
        cell.on                     = switchOn
        cell.onChange               = { [weak self] in
            self?.switchDidChange($0)
        }
    }

    private func configureTextCell(cell: WPTableViewCell) {
        let format                  = selectionFormat ?? "%d"
        
        cell.selectionStyle         = .None
        cell.textLabel?.text        = selectionText
        cell.detailTextLabel?.text  = String(format: format, pickerSelectedValue)
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func configurePickerCell(cell: PickerTableViewCell) {
        cell.selectionStyle         = .None
        cell.minimumValue           = pickerMinimumValue!
        cell.maximumValue           = max(pickerSelectedValue, pickerMaximumValue)
        cell.selectedValue          = pickerSelectedValue
        cell.textFormat             = pickerFormat
        cell.onChange               = { [weak self] in
            self?.pickerDidChange($0)
        }
    }
    
    
    
    // MARK: - Button Handlers Properties
    private func switchDidChange(newValue: Bool) {
        switchOn = newValue
        
        // Show / Hide the Picker Section
        let pickerSectionIndexSet = NSIndexSet(index: pickerSection)
        
        if newValue {
            tableView.insertSections(pickerSectionIndexSet, withRowAnimation: .Fade)
        } else {
            tableView.deleteSections(pickerSectionIndexSet, withRowAnimation: .Fade)
        }
        
        // Hit the Callback
        onChange?(enabled: switchOn, newValue: pickerSelectedValue)
    }
    
    private func pickerDidChange(newValue: Int) {
        pickerSelectedValue = newValue
        
        // Refresh the 'Current Value' row
        if let cell = tableView.cellForRowAtIndexPath(selectedValueIndexPath) as? WPTableViewCell {
            configureTextCell(cell)
        }
        
        // Hit the Callback
        onChange?(enabled: switchOn, newValue: pickerSelectedValue)
    }
    
    
    
    // MARK: - Nested Enums
    private enum Row : String {
        case Value1 = "Value1"
        case Switch = "SwitchCell"
        case Picker = "Picker"
    }
    
    // MARK: - Computed Properties
    private var sections : [[Row]] {
        var sections = [[Row]]()
        
        if switchVisible {
            sections.append([.Switch])
        }
        
        if switchOn || !switchVisible {
            sections.append([.Value1, .Picker])
        }

        return sections
    }
    
    private var pickerSection : Int {
        return switchVisible ? 1 : 0
    }
    
    private var selectedValueIndexPath : NSIndexPath {
        return NSIndexPath(forRow: 0, inSection: pickerSection)
    }
    
    // MARK: - Private Constants
    private let estimatedRowHeight  = CGFloat(300)
    private let sectionWithFooter   = 0
}
