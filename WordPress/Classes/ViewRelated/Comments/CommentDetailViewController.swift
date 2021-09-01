import UIKit

class CommentDetailViewController: UITableViewController {

    // MARK: Properties

    private let comment: Comment

    private var rows = [RowType]()

    // MARK: Initialization

    @objc required init(comment: Comment) {
        self.comment = comment
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTable()
    }

    // MARK: Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

}

// MARK: - Private Helpers

private extension CommentDetailViewController {

    enum RowType {
        case header
        case content
        case replyIndicator
        case textWithDescriptor(descriptor: String, content: String, imageName: String?, action: (() -> Void)?)
    }

    func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
    }

    func configureTable() {
        tableView.tableFooterView = UIView(frame: .zero)
    }

    @objc func editButtonTapped() {
        // NOTE: This depends on the new edit comment feature, which is still ongoing.
        let navigationControllerToPresent = UINavigationController(rootViewController: EditCommentTableViewController(comment: comment))
        navigationControllerToPresent.modalPresentationStyle = .fullScreen
        present(navigationControllerToPresent, animated: true) {
            self.tableView.reloadData()
        }
    }

}
