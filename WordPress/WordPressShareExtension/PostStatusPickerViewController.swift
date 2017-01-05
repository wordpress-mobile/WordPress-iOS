import Foundation
import UIKit
import WordPressShared

class PostStatusPickerViewController: UITableViewController {
    // MARK: - Initializers
    init(statuses: [String: String]) {
        assert(statuses.count > 0, "Let's show at least one status!")

        // Note:  We'll store the sorted Post Statuses, into an array, as a (Key, Description) tuple.
        self.sortedStatuses = statuses.sorted { $0.1 < $1.1 }
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        sortedStatuses = [(String, String)]()
        super.init(coder: coder)
        fatalError("Please, use the main initializer instead")
    }


    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
    }


    // MARK: - UITableView Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedStatuses.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let description = sortedStatuses[indexPath.row].1

        configureCell(cell, description: description)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let status = sortedStatuses[indexPath.row]
        onChange?(status.0, status.1)
        _ = navigationController?.popViewController(animated: true)
    }


    // MARK: - Setup Helpers
    fileprivate func setupView() {
        title = NSLocalizedString("Post Status", comment: "Title for the Post Status Picker")
    }

    fileprivate func setupTableView() {
        // Blur!
        let blurEffect = UIBlurEffect(style: .light)
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = UIVisualEffectView(effect: blurEffect)
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)

        // Fix: Hide the cellSeparators, when the table is empty
        tableView.tableFooterView = UIView()

        // Cells
        tableView.register(WPTableViewCellSubtitle.self, forCellReuseIdentifier: reuseIdentifier)
    }


    // MARK: - Private Helpers
    fileprivate func configureCell(_ cell: UITableViewCell, description: String) {
        // Status' Details
        cell.textLabel?.text = description

        // Style
        WPStyleGuide.Share.configureBlogTableViewCell(cell)
    }


    // MARK: Typealiases
    typealias PickerHandler = (_ postStatus: String, _ description: String) -> Void

    // MARK: - Public Properties
    var onChange: PickerHandler?

    // MARK: - Private Properties
    fileprivate var sortedStatuses: [(String, String)]
    fileprivate var noResultsView: WPNoResultsView!

    // MARK: - Private Constants
    fileprivate let reuseIdentifier = "reuseIdentifier"
    fileprivate let rowHeight       = CGFloat(74)
}
