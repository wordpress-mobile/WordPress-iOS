import Foundation
import WordPressShared


/// The purpose of this class is to display a UIPickerView instance inside a UITableView,
/// and wrap up all of the Picker Delegate / DataSource methods
///
open class PickerTableViewCell: WPTableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    // MARK: - Public Properties

    /// Closure, to be executed on selection change
    ///
    @objc open var onChange : ((_ newValue: Int) -> ())?


    /// String Format, to be applied to the Row Titles
    ///
    @objc open var textFormat: String? {
        didSet {
            picker.reloadAllComponents()
        }
    }


    /// Currently Selected Value
    ///
    open var selectedValue: Int? {
        didSet {
            refreshSelectedValue()
        }
    }


    /// Specifies the Minimum Possible Value
    ///
    @objc open var minimumValue: Int = 0 {
        didSet {
            picker.reloadAllComponents()
        }
    }

    /// Specifies the Maximum Possible Value
    ///
    @objc open var maximumValue: Int = 0 {
        didSet {
            picker.reloadAllComponents()
        }
    }



    // MARK: - Initializers

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupSubviews()
    }

    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }



    // MARK: - Private Helpers

    fileprivate func setupSubviews() {
        // Setup Picker
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = .listForeground
        contentView.addSubview(picker)

        // ContentView: Pin to Left + Right + Top + Bottom edges
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        // Picker: Pin to Top + Bottom + CenterX edges
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        picker.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        picker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        picker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }

    fileprivate func refreshSelectedValue() {
        guard let unwrappedSelectedValue = selectedValue else {
            return
        }

        let row = unwrappedSelectedValue - minimumValue
        picker.selectRow(row, inComponent: 0, animated: false)
    }



    // MARK: UIPickerView Methods

    open func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return numberOfComponentsInPicker
    }

    open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // We *include* the last value, as well
        return maximumValue - minimumValue + 1
    }

    open func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let unwrappedFormat = textFormat ?? "%d"
        let value = row + minimumValue

        return String(format: unwrappedFormat, value)
    }

    open func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let value = row + minimumValue
        onChange?(value)
    }



    // MARK: - Private Properties
    fileprivate let picker                      = UIPickerView()
    fileprivate let numberOfComponentsInPicker  = 1
}
