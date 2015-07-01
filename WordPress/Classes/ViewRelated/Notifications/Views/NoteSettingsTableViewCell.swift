import Foundation


public class NoteSettingsTableViewCell : UITableViewCell
{
    @IBOutlet private var flipSwitch : UISwitch!
    
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
}
