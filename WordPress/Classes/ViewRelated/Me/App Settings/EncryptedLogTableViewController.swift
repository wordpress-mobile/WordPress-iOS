import UIKit
import AutomatticTracks

class EncryptedLogTableViewController: UITableViewController {

    /// Internal storage for the log list
    private var logs: [LogFile] = []

    /// The label displaying the current status
    private let toolbarLabel = UIBarButtonItem(title: "Running", style: .plain, target: nil, action: nil)

    private let eventLogging: EventLogging

    init(eventLogging: EventLogging) {
        self.eventLogging = eventLogging
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Encrypted Log Queue"
        self.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.updateData()

        let item = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addEncryptedLog))
        self.navigationItem.rightBarButtonItem = item

        let name = WPLoggingStack.QueuedLogsDidChangeNotification
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
            self.updateData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([spacer, self.toolbarLabel, spacer], animated: animated)
        tableView.tableFooterView = UIView(frame: .zero) /// hide lines for empty cells

        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.setToolbarItems(nil, animated: animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    // MARK: UITableViewController Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let log = logs[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = log.uuid

        if let date = try? FileManager.default.attributesOfItem(atPath: log.url.path)[.creationDate] as? Date {
            cell.detailTextLabel?.text = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
        }
        else {
            cell.detailTextLabel?.text = "Unknown"
        }

        return cell
    }

    // MARK: Internal Helpers
    private func updateData() {
        self.logs = eventLogging.queuedLogFiles
        self.tableView.reloadData()

        if let date = self.eventLogging.uploadsPausedUntil {
            let dateString = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .medium)
            self.toolbarLabel.title = "Paused until \(dateString)"
        }
        else {
            self.toolbarLabel.title = self.logs.isEmpty ? "All Logs Uploaded" : "Running"
        }
    }

    @objc
    private func addEncryptedLog() {
        do {
            /// For now, just enqueue any file – doesn't have to be the log
            let data = try Data(contentsOf: Bundle.main.url(forResource: "acknowledgements", withExtension: "html")!)

            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try data.write(to: url)

            try self.eventLogging.enqueueLogForUpload(log: LogFile(url: url))
        }
        catch let err {
            let alert = UIAlertController(title: "Unable to create log", message: err.localizedDescription, preferredStyle: .actionSheet)
            self.present(alert, animated: true)
        }
    }
}

fileprivate class SubtitleTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
