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
            numbersLabel.text = "\(total)"
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

        numbersLabel.textColor = AppColor.neutral(.shade40)
    }

    enum OperationType {
        case add
        case del

        var color: UIColor {
            switch self {
            case .add: return AppColor.primary
            case .del: return AppColor.error
            }
        }

        var icon: UIImage {
            switch self {
            case .add: return .gridicon(.plusSmall)
            case .del: return .gridicon(.minusSmall)
            }
        }
    }
}
