import Foundation
import WordPressShared

/// The purpose of this class is to simply display a regular TableViewCell, with a Switch on the right hand side.
///
open class SwitchTableViewCell: WPTableViewCell {
    // MARK: - Public Properties
    @objc open var onChange : ((_ newValue: Bool) -> ())?

    @objc open var name: String {
        get {
            return textLabel?.text ?? String()
        }
        set {
            textLabel?.text = newValue
        }
    }

    @objc open var on: Bool {
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

    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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

        setupContentView()
        setupSwitch()
        setupTextLabel()

        WPStyleGuide.configureTableViewCell(self)
    }

    private func setupContentView() {
        contentView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action: #selector(SwitchTableViewCell.rowWasPressed(_:)))
    }

    private func setupSwitch() {
        flipSwitch = UISwitch()
        flipSwitch.addTarget(self, action: #selector(SwitchTableViewCell.switchDidChange(_:)), for: .valueChanged)
        accessoryView = flipSwitch
    }

    private func setupTextLabel() {
        textLabel?.numberOfLines = 0
        textLabel?.adjustsFontForContentSizeCategory = true
    }

    // MARK: - Private Properties
    fileprivate let tapGestureRecognizer = UITapGestureRecognizer()

    // MARK: - Private Outlets
    @objc public var flipSwitch: UISwitch!
}

class SwitchWithSubtitleTableViewCell: SwitchTableViewCell {
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
