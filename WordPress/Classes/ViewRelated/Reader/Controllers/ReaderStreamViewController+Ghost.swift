import UIKit
import Foundation
import WordPressUI

extension ReaderStreamViewController {
    func showGhost() {
        guard ghostableTableView.superview == nil else {
            return
        }

        ghostableTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ghostableTableView)
        if isEmbeddedInDiscover {
            NSLayoutConstraint.activate([
                ghostableTableView.topAnchor.constraint(equalTo: tableView.tableHeaderView?.bottomAnchor ?? view.topAnchor),
                ghostableTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                ghostableTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                ghostableTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        } else {
            view.addSubview(ghostableTableView)
            NSLayoutConstraint.activate([
                ghostableTableView.widthAnchor.constraint(equalTo: tableView.widthAnchor, multiplier: 1),
                ghostableTableView.heightAnchor.constraint(equalTo: tableView.heightAnchor, multiplier: 1),
                ghostableTableView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
                ghostableTableView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
            ])
        }

        ghostableTableView.accessibilityIdentifier = "Reader Ghost Loading"
        ghostableTableView.cellLayoutMarginsFollowReadableWidth = true

        ghostableTableView.register(ReaderGhostCompactCell.self, forCellReuseIdentifier: "ReaderGhostCompactCell")
        ghostableTableView.register(ReaderGhostRegularCell.self, forCellReuseIdentifier: "ReaderGhostRegularCell")

        let ghostOptions = GhostOptions(displaysSectionHeader: false, reuseIdentifier: isCompact ? "ReaderGhostCompactCell" : "ReaderGhostRegularCell", rowsPerSection: [10])

        let style = GhostStyle()
        ghostableTableView.estimatedRowHeight = 320
        ghostableTableView.removeGhostContent()
        ghostableTableView.displayGhostContent(options: ghostOptions, style: style)
        ghostableTableView.isUserInteractionEnabled = false
        ghostableTableView.cellLayoutMarginsFollowReadableWidth = true
        ghostableTableView.isHidden = false
    }

    func hideGhost() {
        ghostableTableView.removeGhostContent()
        ghostableTableView.removeFromSuperview()
    }
}

private final class ReaderGhostCompactCell: ReaderStreamBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let imageView = makeLeafView(height: 320, width: 1200)
        imageView.layer.cornerRadius = 8
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ReaderPostCell.coverAspectRatio).isActive = true

        let titleLabel = makeLeafView(height: 18, width: .random(in: 140...200))
        let stackView = UIStackView(axis: .vertical, alignment: .leading, spacing: 12, insets: UIEdgeInsets(.vertical, 16), [
            titleLabel,
            UIStackView(axis: .vertical, alignment: .leading, spacing: 8, [
                makeLeafView(height: 10, width: .random(in: 300...600)),
                makeLeafView(height: 10, width: .random(in: 160...240)),
            ]),
            imageView,
            makeLeafView(height: 14, width: .random(in: 200...240))
        ])
        contentView.addSubview(stackView)
        stackView.pinEdges(insets: ReaderStreamBaseCell.insets)

        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ReaderStreamBaseCell.insets.left).isActive = true

        let avatarView = makeAvatarView()
        contentView.addSubview(avatarView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            avatarView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ReaderGhostRegularCell: ReaderStreamBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isCompact = false

        let imageView = makeLeafView(height: 140, width: ReaderPostCell.regularCoverWidth)
        imageView.layer.cornerRadius = 8
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ReaderPostCell.coverAspectRatio).isActive = true

        let titleLabel = makeLeafView(height: 16, width: .random(in: 200...300))

        let leftStackView = UIStackView(axis: .vertical, alignment: .leading, spacing: 12, [
            titleLabel,
            UIStackView(axis: .vertical, alignment: .leading, spacing: 8, [
                makeLeafView(height: 10, width: .random(in: 400...600)),
                makeLeafView(height: 10, width: .random(in: 400...500)),
                makeLeafView(height: 10, width: .random(in: 300...500)),
                makeLeafView(height: 10, width: .random(in: 160...240)),
            ])
        ])

        let stackView = UIStackView(axis: .vertical, alignment: .leading, spacing: 20, insets: UIEdgeInsets(.vertical, 16), [
            makeLeafView(height: 10, width: .random(in: 120...180)),
            UIStackView(axis: .horizontal, alignment: .top, spacing: 18, [
                leftStackView,
                UIView(),
                imageView
            ])
        ])
        contentView.addSubview(stackView)

        stackView.pinEdges(.vertical, to: contentView, insets: UIEdgeInsets(.vertical, 8))
        stackView.pinEdges(.horizontal, to: contentView.readableContentGuide, insets: ReaderPostCell.insets)

        let avatarView = makeAvatarView()
        contentView.addSubview(avatarView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            avatarView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func makeAvatarView() -> UIView {
    let avatarSize: CGFloat = SiteIconViewModel.Size.small.width
    let view = makeLeafView(height: avatarSize, width: avatarSize)
    view.layer.cornerRadius = avatarSize / 2
    return view
}

private func makeLeafView(height: CGFloat, width: CGFloat = CGFloat.random(in: 44...320)) -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.secondarySystemBackground
    NSLayoutConstraint.activate([
        view.widthAnchor.constraint(equalToConstant: width).withPriority(.defaultLow),
        view.heightAnchor.constraint(equalToConstant: height).withPriority(.defaultHigh),
    ])
    view.layer.cornerRadius = 4
    view.layer.masksToBounds = true
    return view
}
