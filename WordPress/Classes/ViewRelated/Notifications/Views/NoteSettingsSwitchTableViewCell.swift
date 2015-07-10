import Foundation


public class NoteSettingsSwitchTableViewCell : WPTableViewCell
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
    
    
    // MARK: - UITapGestureRecognizer Helpers
    public func rowWasPressed(recognizer: UITapGestureRecognizer) {
        // Manually relay the event, since .ValueChanged doesn't get posted if we toggle the switch
        // programatically
        flipSwitch.setOn(!isOn, animated: true)
        switchDidChange(flipSwitch)
    }
    
    // MARK: - UISwitch Helpers
    public func switchDidChange(theSwitch: UISwitch) {
        onChange?(newValue: theSwitch.on)
    }
    
    // MARK: - UIView Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
        
        contentView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action: "rowWasPressed:")
        
        flipSwitch.addTarget(self, action: "switchDidChange:", forControlEvents: .ValueChanged)
        
        WPStyleGuide.configureTableViewCell(self)
    }
    
    // MARK: - Private Properties
    private let tapGestureRecognizer = UITapGestureRecognizer()
    
    // MARK: - Private Outlets
    @IBOutlet private var flipSwitch : UISwitch!
}
