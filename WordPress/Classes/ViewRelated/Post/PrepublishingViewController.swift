import UIKit
import WordPressAuthenticator

private struct PrepublishingOption {
    let title: String
}

class PrepublishingViewController: UITableViewController {
    private let post: Post

    private let completion: (AbstractPost) -> ()

    private let options: [PrepublishingOption] = [
        PrepublishingOption(title: NSLocalizedString("Tags", comment: "Label for Tags"))
    ]

    let nuxButton: NUXButton = {
        let nuxButton = NUXButton()
        nuxButton.isPrimary = true
        nuxButton.setTitle(NSLocalizedString("Publish Now", comment: "Label for a button that publishes the post"), for: .normal)

        return nuxButton
    }()

    init(post: Post, completion: @escaping (AbstractPost) -> ()) {
        self.post = post
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupFooterWithButton()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: WPTableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.reuseIdentifier) as? WPTableViewCell else {
                return WPTableViewCell.init(style: .value1, reuseIdentifier: Constants.reuseIdentifier)
            }
            return cell
        }()

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero

        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = options[indexPath.row].title

        if indexPath.row == 0 {
            // Tags row
            cell.detailTextLabel?.text = post.tags
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = PostTagPickerViewController(tags: post.tags ?? "", blog: post.blog)

        viewController.onValueChanged = { [weak self] tags in
            if !tags.isEmpty {
                WPAnalytics.track(.prepublishingTagsAdded)
            }

            self?.post.tags = tags
            self?.tableView.reloadData()
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc func publish(_ sender: UIButton) {
        navigationController?.dismiss(animated: true) {
            self.completion(self.post)
        }
    }

    private func setupFooterWithButton() {
        let footer = UIView(frame: Constants.footerFrame)
        footer.addSubview(nuxButton)
        footer.pinSubviewToSafeArea(nuxButton, insets: Constants.nuxButtonInsets)
        nuxButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = footer
        nuxButton.addTarget(self, action: #selector(publish(_:)), for: .touchUpInside)
    }

    private enum Constants {
        static let reuseIdentifier = "wpTableViewCell"
        static let nuxButtonInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        static let footerFrame = CGRect(x: 0, y: 0, width: 100, height: 40)
    }
}

class PrepublishingNavigationController: UINavigationController, BottomSheetPresentable {
    var initialHeight: CGFloat = 200
}

typealias UIBottomSheetPresentable = BottomSheetPresentable & UIViewController

protocol BottomSheetPresentable {
    var initialHeight: CGFloat { get }
}
