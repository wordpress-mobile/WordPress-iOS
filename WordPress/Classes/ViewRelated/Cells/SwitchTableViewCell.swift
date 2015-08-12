import Foundation


/**
*  @class           SwitchTableViewCell
*  @brief           The purpose of this class is to simply display a regular TableViewCell, with a Switch
*                   on the right hand side.
*/

public class SwitchTableViewCell : WPTableViewCell
{
    // MARK: - Public Properties
    public var onChange : ((newValue: Bool) -> ())?
    
    public var name : String {
        get {
            return textLabel?.text ?? String()
        }
        set {
            textLabel?.text = newValue
        }
    }
    
    public var isOn : Bool {
        get {
            return flipSwitch.on
        }
        set {
            flipSwitch.on = newValue
        }
    }
    
    
    
    // MARK: - Initializers
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }
    
    
    
    // MARK: - UITapGestureRecognizer Helpers
    @IBAction private func rowWasPressed(recognizer: UITapGestureRecognizer) {
        // Manually relay the event, since .ValueChanged doesn't get posted if we toggle the switch
        // programatically
        flipSwitch.setOn(!isOn, animated: true)
        switchDidChange(flipSwitch)
    }
    
    
    
    // MARK: - UISwitch Helpers
    @IBAction private func switchDidChange(theSwitch: UISwitch) {
        onChange?(newValue: theSwitch.on)
    }
    
    
    
    // MARK: - Private Helpers
    private func setupSubviews() {
        selectionStyle = .None
        
        contentView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action: "rowWasPressed:")
        
        flipSwitch = UISwitch()
        flipSwitch.addTarget(self, action: "switchDidChange:", forControlEvents: .ValueChanged)
        accessoryView = flipSwitch
        
        WPStyleGuide.configureTableViewCell(self)
    }
    
    
    
    // MARK: - Private Properties
    private let tapGestureRecognizer = UITapGestureRecognizer()
    
    // MARK: - Private Outlets
    private var flipSwitch : UISwitch!
}
