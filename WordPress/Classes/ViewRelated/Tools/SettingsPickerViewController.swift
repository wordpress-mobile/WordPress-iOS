import Foundation
import WordPressShared


public class SettingsPickerViewController : UITableViewController
{
    // MARK: - Switch Settings
    public var switchRowVisible     = true
    public var switchRowText        = String()
    public var switchRowValue       = false

    // MARK: - Status Settings
    public var selectedRowText      : String!
    public var selectedRowFormat    : String!

    // MARK: - Picker Settings
    public var pickerFormat         : String?
    public var pickerSelectedValue  : Int?
    public var pickerMinimumValue   : Int!
    public var pickerMaximumValue   : Int!
    
    
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        assert(selectedRowText     != nil)
        assert(selectedRowFormat   != nil)
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
        cell.selectionStyle         = .None
        cell.textLabel?.text        = selectedRowText
        cell.detailTextLabel?.text  = String(format: selectedRowFormat, pickerSelectedValue!)
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    private func configurePickerCell(cell: PickerTableViewCell) {
        var safeMaxValue            = pickerSelectedValue ?? pickerMaximumValue!
        safeMaxValue                = max(safeMaxValue, pickerMaximumValue)
        
        cell.selectionStyle         = .None
        cell.minimumValue           = pickerMinimumValue!
        cell.maximumValue           = safeMaxValue
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
    }
    
    private func pickerDidChange(newValue: Int) {
        pickerSelectedValue = newValue
        tableView.reloadRowsAtIndexPaths([pickerIndexPath], withRowAnimation: .None)
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
        let pickerSection = switchRowVisible ? 1 : 0
        return NSIndexPath(forRow: 0, inSection: pickerSection)
    }
    
    // MARK: - Nested Enums
    private enum Row : String {
        case Value1 = "Value1"
        case Switch = "SwitchCell"
        case Picker = "Picker"
    }
}
