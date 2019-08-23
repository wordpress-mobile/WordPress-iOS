import Gridicons

class BlogDetailsSectionHeaderView: UITableViewHeaderFooterView {
    typealias EllipsisCallback = (BlogDetailsSectionHeaderView) -> Void
    @IBOutlet private var titleLabel: UILabel?

    @objc @IBOutlet private(set) var ellipsisButton: UIButton? {
        didSet {
            ellipsisButton?.setImage(Gridicon.iconOfType(.ellipsis).imageWithTintColor(.neutral(.shade30)), for: .normal)
        }
    }

    @objc var title: String = "" {
        didSet {
            titleLabel?.text = title.uppercased()
        }
    }

    @objc var ellipsisButtonDidTouch: EllipsisCallback?

    @IBAction func ellipsisTapped() {
        ellipsisButtonDidTouch?(self)
    }
}
