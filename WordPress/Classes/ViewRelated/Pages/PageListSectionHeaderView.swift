import UIKit

class PageListSectionHeaderView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separator: UIView!

    func setTitle(_ title: String) {
        titleLabel.text = title.uppercased(with: .current)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .listBackground
        titleLabel.backgroundColor = .listBackground
        WPStyleGuide.applyBorderStyle(separator)
    }
}
