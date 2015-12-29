import Foundation
import WordPressShared


/// The purpose of this class is to display a UIPickerView instance inside a UITableView,
/// and wrap up all of the Picker Delegate / DataSource methods

public class PickerTableViewCell : WPTableViewCell, UIPickerViewDelegate, UIPickerViewDataSource
{
    // MARK: - Public Properties
    
    
    /// Closure, to be executed on selection change
    public var onChange : ((newValue: Int) -> ())?
    
    
    /// String Format, to be applied to the Row Titles
    public var textFormat : String? {
        didSet {
            picker.reloadAllComponents()
        }
    }
    
    
    /// Currently Selected Value
    public var selectedValue : Int? {
        didSet {
            refreshSelectedValue()
        }
    }
    
    
    /// Specifies the Minimum Possible Value
    public var minimumValue : Int = 0 {
        didSet {
            picker.reloadAllComponents()
        }
    }

    /// Specifies the Maximum Possible Value
    public var maximumValue : Int = 0 {
        didSet {
            picker.reloadAllComponents()
        }
    }
    
    
    
    // MARK: - Initializers
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupSubviews()
    }
    
    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }



    // MARK: - Private Helpers
    private func setupSubviews() {
        // Setup Picker
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = UIColor.whiteColor()
        contentView.addSubview(picker)
        
        // ContentView: Pin to Left + Right edges
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
        contentView.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
        
        // Picker: Pin to Top + Bottom + CenterX edges
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.topAnchor.constraintEqualToAnchor(contentView.topAnchor).active = true
        picker.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor).active = true
        picker.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
        picker.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
    }
    
    private func refreshSelectedValue() {
        guard let unwrappedSelectedValue = selectedValue else {
            return
        }
        
        let row = unwrappedSelectedValue - minimumValue
        picker.selectRow(row, inComponent: 0, animated: false)
    }
    
    
    
    // MARK: UIPickerView Methods
    public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return numberOfComponentsInPicker
    }

    public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // We *include* the last value, as well
        return maximumValue - minimumValue + 1
    }
    
    public func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let unwrappedFormat = textFormat ?? "%d"
        let value = row + minimumValue
        
        return String(format: unwrappedFormat, value)
    }
    
    public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let value = row + minimumValue
        onChange?(newValue: value)
    }



    // MARK: - Private Properties
    private let picker                      = UIPickerView()
    private let numberOfComponentsInPicker  = 1
}
