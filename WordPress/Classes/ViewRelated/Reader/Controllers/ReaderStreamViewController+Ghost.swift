import UIKit
import Foundation
import WordPressUI

extension ReaderStreamViewController {
    /// Show ghost card cells at the top of the tableView
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

        ghostableTableView.register(ReaderGhostCell.self, forCellReuseIdentifier: "ReaderGhostCell")
        let ghostOptions = GhostOptions(displaysSectionHeader: false, reuseIdentifier: "ReaderGhostCell", rowsPerSection: [10])

        let style = GhostStyle()
        ghostableTableView.estimatedRowHeight = 200
        ghostableTableView.removeGhostContent()
        ghostableTableView.displayGhostContent(options: ghostOptions, style: style)
        ghostableTableView.isUserInteractionEnabled = false
        ghostableTableView.isHidden = false
    }

    /// Hide the ghost card cells
    func hideGhost() {
        ghostableTableView.removeGhostContent()
        ghostableTableView.removeFromSuperview()
    }
}

private final class ReaderGhostCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        func makeLeafView(height: CGFloat, width: CGFloat = CGFloat.random(in: 44...320)) -> UIView {
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

        let imageView = makeLeafView(height: 320, width: 1200)
        imageView.layer.cornerRadius = 8
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.5).isActive = true

        let insets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        let stackView = UIStackView(axis: .vertical, alignment: .leading, spacing: 16, insets: insets, [
            makeLeafView(height: 16, width: .random(in: 140...200)),
            makeLeafView(height: 24, width: .random(in: 200...600)),
            imageView,
            makeLeafView(height: 16, width: .random(in: 200...240))
        ])
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdgeMargins(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
