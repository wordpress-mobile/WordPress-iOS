import Foundation
import UIKit
import WordPressShared

class PostStatusPickerViewController : UITableViewController
{
    // MARK: - Initializers
    init(statuses : [String: String]) {
        assert(statuses.count > 0, "Let's show at least one status!")

        // Note:  We'll store the sorted Post Statuses, into an array, as a (Key, Description) tuple.
        self.sortedStatuses = statuses.sort { $0.1 < $1.1 }
        super.init(style: .Plain)
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
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedStatuses.count
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        let description = sortedStatuses[indexPath.row].1

        configureCell(cell, description: description)

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let status = sortedStatuses[indexPath.row]
        onChange?(postStatus: status.0, description: status.1)
        navigationController?.popViewControllerAnimated(true)
    }


    // MARK: - Setup Helpers
    private func setupView() {
        title = NSLocalizedString("Post Status", comment: "Title for the Post Status Picker")
    }

    private func setupTableView() {
        // Blur!
        let blurEffect = UIBlurEffect(style: .Light)
        tableView.backgroundColor = UIColor.clearColor()
        tableView.backgroundView = UIVisualEffectView(effect: blurEffect)
        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)

        // Fix: Hide the cellSeparators, when the table is empty
        tableView.tableFooterView = UIView()

        // Cells
        tableView.registerClass(WPTableViewCellSubtitle.self, forCellReuseIdentifier: reuseIdentifier)
    }


    // MARK: - Private Helpers
    private func configureCell(cell: UITableViewCell, description: String) {
        // Status' Details
        cell.textLabel?.text = description

        // Style
        WPStyleGuide.Share.configureBlogTableViewCell(cell)
    }


    // MARK: Typealiases
    typealias PickerHandler = (postStatus: String, description: String) -> Void

    // MARK: - Public Properties
    var onChange                : PickerHandler?

    // MARK: - Private Properties
    private var sortedStatuses  : [(String, String)]
    private var noResultsView   : WPNoResultsView!

    // MARK: - Private Constants
    private let reuseIdentifier = "reuseIdentifier"
    private let rowHeight       = CGFloat(74)
}
