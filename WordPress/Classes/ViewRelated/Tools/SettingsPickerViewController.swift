import Foundation
import WordPressShared


/**
 *  @class          SettingsPickerViewController
 *  @details        Renders a table with the following structure:
 *
 *                  Section | Row   ContentView
 *                  0           1   [Text]  [Switch]    < Shows / Hides Section 1
 *                  1           0   [Text]  [Text]
 *                  1           1   [Picker]
 */

public class SettingsPickerViewController : UITableViewController
{
    /**
     *  @details    Indicates whether a Switch row should be rendered on top, allowing
     *              the user to Enable / Disable the picker
     */
    public var switchRowVisible = true
    
    /**
     *  @details    Specifies the Switch value, to be displayed on the first row
     *              (granted that `switchRowVisible` is set to true)
     */
    public var switchRowValue = false
    
    /**
     *  @details    Text to be displayed by the first row's Switch
     */
    public var switchRowText : String!

    /**
     *  @details    Text to be displayed in the "Currently Selected value" row
     */
    public var selectedRowText : String!
    
    /**
     *  @details    Indicates the format to be used in the "Currently Selected Value" row
     */
    public var selectedRowFormat : String?

    /**
     *  @details    String format, to be applied over the Picker Rows
     */
    public var pickerFormat : String?
    
    /**
     *  @details    Currently selected value.
     */
    public var pickerSelectedValue : Int!
    
    /**
     *  @details    Picker's minimum value.
     */
    public var pickerMinimumValue : Int!
    
    /**
     *  @details    Picker's maximum value.
     */
    public var pickerMaximumValue : Int!
    

    /**
     *  @details    Closure to be executed whenever the Switch / Picker is updated
     */
    public var onChange : ((enabled : Bool, newValue: Int) -> ())?
    
    
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        assert(selectedRowText     != nil)
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
        cell.name                   = switchRowText
        cell.on                     = switchRowValue
        cell.onChange               = { [weak self] in
            self?.pressedSwitchRow($0)
        }
    }

    private func configureTextCell(cell: WPTableViewCell) {
        let selectionFormat         = selectedRowFormat ?? "%d"
        
        cell.selectionStyle         = .None
        cell.textLabel?.text        = selectedRowText
        cell.detailTextLabel?.text  = String(format: selectionFormat, pickerSelectedValue)
        
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
    private func pressedSwitchRow(newValue: Bool) {
        switchRowValue = newValue
        
        let pickerSection = NSIndexSet(index: pickerIndexPath.section)
        
        if newValue {
            tableView.insertSections(pickerSection, withRowAnimation: .Fade)
        } else {
            tableView.deleteSections(pickerSection, withRowAnimation: .Fade)
        }
        
        onChange?(enabled: switchRowValue, newValue: pickerSelectedValue)
    }
    
    private func pickerDidChange(newValue: Int) {
        pickerSelectedValue = newValue
        tableView.reloadRowsAtIndexPaths([pickerIndexPath], withRowAnimation: .None)
        
        onChange?(enabled: switchRowValue, newValue: pickerSelectedValue)
    }
    
    
    
    // MARK: - Private Constants
    private let estimatedRowHeight = CGFloat(300)
    
    // MARK: - Computed Properties
    private var sections : [[Row]] {
        var sections = [[Row]]()
        
        if switchRowVisible {
            sections.append([Row.Switch])
        }
        
        if switchRowValue || !switchRowVisible {
            sections.append([.Value1, .Picker])
        }

        return sections
    }
    
    private var pickerIndexPath : NSIndexPath {
        let section = switchRowVisible ? 1 : 0
        return NSIndexPath(forRow: 0, inSection: section)
    }
    
    // MARK: - Nested Enums
    private enum Row : String {
        case Value1 = "Value1"
        case Switch = "SwitchCell"
        case Picker = "Picker"
    }
}
