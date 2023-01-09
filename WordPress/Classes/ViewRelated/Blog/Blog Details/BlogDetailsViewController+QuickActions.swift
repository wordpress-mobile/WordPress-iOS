import UIKit

// TODO: Consider completely removing all Quick Action logic
extension BlogDetailsViewController {

    @objc func quickActionsSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}
        return BlogDetailsSection(title: nil,
                                  rows: [row],
                                  footerTitle: nil,
                                  category: .quickAction)
    }

    @objc func isAccessibilityCategoryEnabled() -> Bool {
        tableView.traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    @objc func configureQuickActions(cell: QuickActionsCell) {
        let actionItems = createActionItems()

        cell.configure(with: actionItems)
    }

    private func createActionItems() -> [ActionRow.Item] {
        let actionItems: [ActionRow.Item] = [
            .init(image: .gridicon(.statsAlt), title: NSLocalizedString("Stats", comment: "Noun. Abbv. of Statistics. Links to a blog's Stats screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showStats(from: .button)
            },
            .init(image: .gridicon(.posts), title: NSLocalizedString("Posts", comment: "Noun. Title. Links to the blog's Posts screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showPostList(from: .button)
            },
            .init(image: .gridicon(.image), title: NSLocalizedString("Media", comment: "Noun. Title. Links to the blog's Media library.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showMediaLibrary(from: .button)
            },
            .init(image: .gridicon(.pages), title: NSLocalizedString("Pages", comment: "Noun. Title. Links to the blog's Pages screen.")) { [weak self] in
                self?.tableView.deselectSelectedRowWithAnimation(false)
                self?.showPageList(from: .button)
            }
        ]

        return actionItems
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
        setupCell()
    }

    private func setupConstraints() {
        actionRow.translatesAutoresizingMaskIntoConstraints = false

        let widthConstraint = actionRow.widthAnchor.constraint(equalToConstant: Constants.maxQuickActionsWidth)
        widthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            actionRow.topAnchor.constraint(equalTo: contentView.topAnchor),
            actionRow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            actionRow.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            actionRow.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            widthConstraint
        ])
    }

    private func setupCell() {
        selectionStyle = .none
    }

    private enum Constants {
        static let maxQuickActionsWidth: CGFloat = 390
    }
}
