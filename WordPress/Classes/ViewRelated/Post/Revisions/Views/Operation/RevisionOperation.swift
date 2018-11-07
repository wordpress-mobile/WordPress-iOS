import Gridicons


class RevisionOperation: NSObject {
    @IBOutlet private (set) var internalView: RevisionOperationView!

    init(_ type: RevisionOperationView.OperationType) {
        super.init()

        Bundle.main.loadNibNamed(RevisionOperation.classNameWithoutNamespaces(), owner: self, options: nil)

        assert(internalView != nil)

        internalView.type = type
    }
}


class RevisionOperationView: UIView {
    @IBOutlet private var imageView: CircularImageView!
    @IBOutlet private var numbersLabel: UILabel!

    var total: Int = 0 {
        didSet {
            isHidden = total == 0
            numbersLabel.text = total > 99 ? "\(total)+" : "\(total)"
        }
    }

    var type: OperationType = .add {
        didSet {
            imageView.backgroundColor = type.color
            imageView.image = type.icon.imageWithTintColor(.white)
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()

        numbersLabel.textColor = WPStyleGuide.greyDarken10()
    }


    enum OperationType {
        case add
        case del

        var color: UIColor {
            switch self {
            case .add: return WPStyleGuide.wordPressBlue()
            case .del: return WPStyleGuide.errorRed()
            }
        }

        var icon: UIImage {
            switch self {
            case .add: return Gridicon.iconOfType(.minusSmall)
            case .del: return Gridicon.iconOfType(.plusSmall)
            }
        }
    }
}
