import UIKit
import WordPressUI

class TextWithAccessoryButtonCell: WPReusableTableViewCell, NibLoadable {
    var buttonText: String? {
        get {
            button?.configuration?.title
        }
        set {
            button?.configuration?.title = newValue
        }
    }

    @IBOutlet private var mainLabel: UILabel? {
        didSet {
            mainLabel?.textColor = .secondaryLabel
        }
    }
    @IBOutlet private var secondaryLabel: UILabel?
    @IBOutlet public private(set) var button: UIButton?

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

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
        button?.setActivityIndicatorVisible(false)
    }
}

private extension TextWithAccessoryButtonCell {
    func initialSetup() {
        button?.configureAsPrimaryNUXButton()
    }

    @IBAction func buttonTapped(_ button: UIButton) {
        onButtonTap?()
    }
}
