import Gridicons

class BlogDetailsSectionHeaderView: UITableViewHeaderFooterView {
    typealias EllipsisCallback = () -> Void

    @IBOutlet private var ellipsisButton: UIButton? {
        didSet {
            ellipsisButton?.setImage(Gridicon.iconOfType(.ellipsis).imageWithTintColor(WPStyleGuide.grey()), for: .normal)
        }
    }

    @objc var callback: EllipsisCallback?

    @IBAction func ellipsisTapped() {
        callback?()
    }
}
