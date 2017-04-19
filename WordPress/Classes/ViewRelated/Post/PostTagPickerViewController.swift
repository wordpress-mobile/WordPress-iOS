import Foundation
import WordPressShared

class PostTagPickerViewController: UITableViewController {
    var tags: String
    var onValueChanged: ((String) -> Void)?

    init(tags: String) {
        self.tags = tags
        super.init(style: .grouped)
        textView.text = tags
        title = NSLocalizedString("Tags", comment: "Title for the tag selector view")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if textView.text != tags {
            onValueChanged?(textView.text)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        textView.delegate = self
    }

    // MARK: - Views

    let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.returnKeyType = .done
        textView.font = WPStyleGuide.tableviewTextFont()
        textView.textColor = WPStyleGuide.darkGrey()
        textView.isScrollEnabled = false

        var inset = textView.textContainerInset
        inset.left = 0
        inset.right = 0
        textView.textContainerInset = inset
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    lazy var textViewCell: WPTableViewCell = {
        let textView = self.textView
        let cell = WPTableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.contentView.addSubview(textView)

        let guide = cell.contentView.readableContentGuide
        cell.contentView.pinSubviewToAllEdgesReadable(textView)

        return cell
    }()

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return textViewCell
    }
}

// MARK: - Text View Delegate
extension PostTagPickerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Remove any space before a comma, and allow one space at most after.
        let regexp = try! NSRegularExpression(pattern: "\\s*(,(\\s(?=\\s))?)\\s*", options: [])
        let text = textView.text ?? ""
        let range = NSRange(location: 0, length: (text as NSString).length)
        textView.text = regexp.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
    }
}
