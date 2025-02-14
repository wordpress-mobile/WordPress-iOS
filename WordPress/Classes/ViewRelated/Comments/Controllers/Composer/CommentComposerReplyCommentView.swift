import UIKit
import WordPressUI

final class CommentComposerReplyCommentView: UIView, UITableViewDataSource {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let comment: Comment
    private let helper = ReaderCommentsHelper()
    private lazy var heightConstraints = tableView.heightAnchor.constraint(equalToConstant: 120)

    init(comment: Comment) {
        self.comment = comment

        super.init(frame: .zero)

        addSubview(tableView)
        tableView.pinEdges()

        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.register(CommentContentTableViewCell.defaultNib, forCellReuseIdentifier: CommentContentTableViewCell.defaultReuseID)

        tableView.dataSource = self
        heightConstraints.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentContentTableViewCell.defaultReuseID) as! CommentContentTableViewCell
        cell.configure(viewModel: .init(comment: comment), helper: helper) { [weak self, weak cell] _ in
            guard let self, let cell else { return }
            self.didUpdateHeight(cell)
        }
        cell.hideActions()
        return cell
    }

    private func didUpdateHeight(_ cell: CommentContentTableViewCell) {
        UIView.performWithoutAnimation {
            tableView.performBatchUpdates({})
            heightConstraints.constant = min(130, cell.systemLayoutSizeFitting(bounds.size)
                .height + 8) // bottom padding
        }
    }
}
