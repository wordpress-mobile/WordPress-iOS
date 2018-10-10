import Foundation


/// The purpose of this class is to simply display a regular TableViewCell, with a Checkmark as accessoryType.
///
@objc class CheckmarkTableViewCell: WPTableViewCell {
    @objc open var on: Bool = false {
        didSet {
            accessoryType = on ? .checkmark : .none
        }
    }

    @objc open var title: String {
        get {
            return textLabel?.text ?? ""
        }
        set {
            textLabel?.text = newValue
        }
    }

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


    // MARK: Private methods

    private func setupSubviews() {
        selectionStyle = .none

        WPStyleGuide.configureTableViewCell(self)
    }
}
