import Gridicons

class BlogDetailsSectionHeaderView: UITableViewHeaderFooterView {
    typealias EllipsisCallback = (BlogDetailsSectionHeaderView) -> Void
    @IBOutlet private var titleLabel: UILabel?

    @objc @IBOutlet private(set) var ellipsisButton: UIButton? {
        didSet {
            ellipsisButton?.setImage(Gridicon.iconOfType(.ellipsis).imageWithTintColor(.listIcon), for: .normal)
        }
    }

    @objc var title: String = "" {
        didSet {
            titleLabel?.text = title.uppercased()
        }
    }

    @objc var ellipsisButtonDidTouch: EllipsisCallback?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel?.textColor = .textSubtle
    }

    @IBAction func ellipsisTapped() {
        ellipsisButtonDidTouch?(self)
    }
}
