import Gridicons

class BlogDetailsSectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private var titleLabel: UILabel?

    @objc @IBOutlet private(set) var ellipsisButton: UIButton? {
        didSet {
            ellipsisButton?.setImage(UIImage.gridicon(.ellipsis).imageWithTintColor(.listIcon), for: .normal)
        }
    }

    @objc var title: String = "" {
        didSet {
            titleLabel?.text = title.uppercased()
        }
    }

    @objc var ellipsisButtonDidTouch: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel?.textColor = .textSubtle
    }

    @IBAction func ellipsisTapped() {
        ellipsisButtonDidTouch?()
    }
}
