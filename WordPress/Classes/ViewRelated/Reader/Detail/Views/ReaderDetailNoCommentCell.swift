import UIKit

class ReaderDetailNoCommentCell: UITableViewCell, NibReusable {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!

    private lazy var jetpackBadge: JetpackButton = {
        let button = JetpackButton(style: .badge)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var jetpackBadgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(jetpackBadge)
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .basicBackground
        titleLabel.textColor = .textSubtle

        guard JetpackBrandingVisibility.all.enabled else {
            return
        }

        stackView.addArrangedSubview(jetpackBadgeView)
        NSLayoutConstraint.activate([
            jetpackBadge.topAnchor.constraint(equalTo: jetpackBadgeView.topAnchor, constant: Self.jetpackBadgeTopInset),
            jetpackBadge.bottomAnchor.constraint(equalTo: jetpackBadgeView.bottomAnchor, constant: -Self.jetpackBadgeBottomInset),
            jetpackBadge.centerXAnchor.constraint(equalTo: jetpackBadgeView.centerXAnchor)
        ])
    }
    static let jetpackBadgeTopInset: CGFloat = 30
    static let jetpackBadgeBottomInset: CGFloat = 6
}
