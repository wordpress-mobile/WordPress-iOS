import UIKit

class PrepublishingViewController: UITableViewController {
    private let post: Post

    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: Constants.reuseIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.reuseIdentifier)

        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.text = "Tags"

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = PostTagPickerViewController(tags: post.tags ?? "", blog: post.blog)

        viewController.onValueChanged = { [weak self] tags in
            self?.post.tags = tags
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private enum Constants {
        static let reuseIdentifier = "wpTableViewCell"
    }
}

class PrepublishingNavigationController: UINavigationController, BottomSheetPresentable {
    var initialHeight: CGFloat = 200
}

typealias UIBottomSheetPresentable = BottomSheetPresentable & UIViewController

protocol BottomSheetPresentable {
    var initialHeight: CGFloat { get }
}
