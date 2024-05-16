import UIKit
import WordPressShared
import DesignSystem

final class StatsGhostSingleValueCell: StatsGhostBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let ghostView = UIView()
        ghostView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ghostView)
        topConstraint = ghostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .DS.Padding.single)
        topConstraint?.isActive = true
        NSLayoutConstraint.activate([
            ghostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .DS.Padding.double),
            ghostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.DS.Padding.double),
            ghostView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.35),
            ghostView.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
