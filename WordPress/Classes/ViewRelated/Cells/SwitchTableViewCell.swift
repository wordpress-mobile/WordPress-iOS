import Foundation
import WordPressShared

/// The purpose of this class is to simply display a regular TableViewCell, with a Switch on the right hand side.
///
open class SwitchTableViewCell : WPTableViewCell
{
    // MARK: - Public Properties
    open var onChange : ((_ newValue: Bool) -> ())?

    open var name : String {
        get {
            return textLabel?.text ?? String()
        }
        set {
            textLabel?.text = newValue
        }
    }

    open var on : Bool {
        get {
            return flipSwitch.isOn
        }
        set {
            flipSwitch.isOn = newValue
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
        self.init(style: .default, reuseIdentifier: nil)
    }


    // MARK: - UITapGestureRecognizer Helpers
    @IBAction func rowWasPressed(_ recognizer: UITapGestureRecognizer) {
        // Manually relay the event, since .ValueChanged doesn't get posted if we toggle the switch
        // programatically
        flipSwitch.setOn(!on, animated: true)
        switchDidChange(flipSwitch)
    }



    // MARK: - UISwitch Helpers
    @IBAction func switchDidChange(_ theSwitch: UISwitch) {
        onChange?(theSwitch.isOn)
    }



    // MARK: - Private Helpers
    fileprivate func setupSubviews() {
        selectionStyle = .none

        contentView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action: #selector(SwitchTableViewCell.rowWasPressed(_:)))

        flipSwitch = UISwitch()
        flipSwitch.addTarget(self, action: #selector(SwitchTableViewCell.switchDidChange(_:)), for: .valueChanged)
        accessoryView = flipSwitch

        WPStyleGuide.configureTableViewCell(self)
    }



    // MARK: - Private Properties
    fileprivate let tapGestureRecognizer = UITapGestureRecognizer()

    // MARK: - Private Outlets
    fileprivate var flipSwitch : UISwitch!
}
