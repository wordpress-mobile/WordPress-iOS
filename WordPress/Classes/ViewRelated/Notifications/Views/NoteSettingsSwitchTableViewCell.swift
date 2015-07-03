import Foundation


public class NoteSettingsSwitchTableViewCell : UITableViewCell
{
    // MARK: - Public Properties
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
        flipSwitch.setOn(!isOn, animated: true)
    }
    
    // MARK: - UIView Methods
    public override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
        
        contentView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action: "rowWasPressed:")
        
        WPStyleGuide.configureTableViewCell(self)
    }
    
    // MARK: - Private Properties
    private let tapGestureRecognizer = UITapGestureRecognizer()
    
    // MARK: - Private Outlets
    @IBOutlet private var flipSwitch : UISwitch!
}
