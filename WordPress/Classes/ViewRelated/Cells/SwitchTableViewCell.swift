import Foundation
import WordPressShared

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
    
    public var on : Bool {
        get {
            return flipSwitch.on
        }
        set {
            flipSwitch.on = newValue
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

    public convenience init() {
        self.init(style: .Default, reuseIdentifier: nil)
    }
    
    
    // MARK: - UITapGestureRecognizer Helpers
    @IBAction func rowWasPressed(recognizer: UITapGestureRecognizer) {
        // Manually relay the event, since .ValueChanged doesn't get posted if we toggle the switch
        // programatically
        flipSwitch.setOn(!on, animated: true)
        switchDidChange(flipSwitch)
    }
    
    
    
    // MARK: - UISwitch Helpers
    @IBAction func switchDidChange(theSwitch: UISwitch) {
        onChange?(newValue: theSwitch.on)
    }
    
    
    
    // MARK: - Private Helpers
    private func setupSubviews() {
        selectionStyle = .None
        
        contentView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action: #selector(SwitchTableViewCell.rowWasPressed(_:)))
        
        flipSwitch = UISwitch()
        flipSwitch.addTarget(self, action: #selector(SwitchTableViewCell.switchDidChange(_:)), forControlEvents: .ValueChanged)
        accessoryView = flipSwitch
        
        WPStyleGuide.configureTableViewCell(self)
    }
    
    
    
    // MARK: - Private Properties
    private let tapGestureRecognizer = UITapGestureRecognizer()
    
    // MARK: - Private Outlets
    private var flipSwitch : UISwitch!
}
