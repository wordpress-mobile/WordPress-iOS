import UIKit

class TextWithAccessoryButtonCell: WPReusableTableViewCell {
    var buttonText: String? {
        get {
            return button.title(for: .normal)
        }
        set {
            button.setTitle(newValue, for: .normal)
            button.sizeToFit()
        }
    }
    var onButtonPressed: (() -> Void)?

    private let button = UIButton()

    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        accessoryView = button
    }
}

private extension TextWithAccessoryButtonCell {
    func initialSetup() {
        WPStyleGuide.configureTableViewCell(self)
        button.titleLabel?.font = WPStyleGuide.tableviewTextFont()
        button.setTitleColor(WPStyleGuide.wordPressBlue(), for: .normal)
        button.addTarget(self, action: #selector(TextWithAccessoryButtonCell.buttonPressed(_:)), for: [.touchUpInside])
        accessoryView = button
    }

    @objc func buttonPressed(_ button: UIButton) {
        onButtonPressed?()
    }
}
