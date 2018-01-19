import UIKit

class TextWithAccessoryButtonCell: WPReusableTableViewCell {
    var buttonText: String? {
        get {
            return button?.title(for: .normal)
        }
        set {
            button?.setTitle(newValue, for: .normal)
            button?.sizeToFit()
        }
    }

    @IBOutlet private var mainLabel: UILabel?
    @IBOutlet private var secondaryLabel: UILabel?
    @IBOutlet public private(set) var button: LoginButton?

    var onButtonTap: (() -> Void)?

    public var mainLabelText: String? {
        didSet {
            mainLabel?.text = mainLabelText
        }
    }

    public var secondaryLabelText: String? {
        didSet {
            let hidden = secondaryLabelText?.nonEmptyString == nil

            secondaryLabel?.isHidden = hidden
            secondaryLabel?.text = secondaryLabelText
        }
    }


    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initialSetup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        button?.showActivityIndicator(false)
    }
}

private extension TextWithAccessoryButtonCell {
    func initialSetup() {
        button?.isPrimary = true
    }

    @IBAction func buttonTapped(_ button: LoginButton) {
        onButtonTap?()
    }
}
