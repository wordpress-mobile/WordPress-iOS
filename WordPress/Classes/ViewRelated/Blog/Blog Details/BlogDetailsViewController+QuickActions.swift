import UIKit

extension BlogDetailsViewController {
    @objc func quickActionsSectionViewModel() -> BlogDetailsSection {
        return BlogDetailsSection(title: nil,
                                  rows: [BlogDetailsRow()],
                                  footerTitle: nil,
                                  category: .quickAction)
    }
}

@objc class QuickActionsCell: UITableViewCell {
    private var actionRow: ActionRow!

    func configure(with items: [ActionRow.Item]) {
        guard actionRow == nil else {
            return
        }

        actionRow = ActionRow(items: items)
        contentView.addSubview(actionRow)

        setupConstraints()
    }

    private func setupConstraints() {
        actionRow.translatesAutoresizingMaskIntoConstraints = false

        let widthConstraint = actionRow.widthAnchor.constraint(equalToConstant: 350)
        widthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            actionRow.topAnchor.constraint(equalTo: contentView.topAnchor),
            actionRow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            actionRow.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            actionRow.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            actionRow.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            widthConstraint
        ])
    }
}
