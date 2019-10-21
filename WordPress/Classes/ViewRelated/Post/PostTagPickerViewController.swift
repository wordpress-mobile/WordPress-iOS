import Foundation
import CocoaLumberjack
import WordPressShared

class PostTagPickerViewController: UIViewController {
    private let originalTags: [String]
    @objc var onValueChanged: ((String) -> Void)?
    @objc let blog: Blog
    @objc let keyboardObserver = TableViewKeyboardObserver()

    @objc init(tags: String, blog: Blog) {
        originalTags = PostTagPickerViewController.extractTags(from: tags)

        self.blog = blog
        super.init(nibName: nil, bundle: nil)
        textView.text = normalizeInitialTags(tags: originalTags)
        textViewDidChange(textView)
        title = NSLocalizedString("Tags", comment: "Title for the tag selector view")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate let textView = UITextView()
    private let textViewContainer = UIView()
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)
    fileprivate var dataSource: PostTagPickerDataSource = LoadingDataSource() {
        didSet {
            tableView.dataSource = dataSource
            reloadTableData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureTableViewColors(tableView: tableView)

        view.backgroundColor = .listBackground

        textView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: SuggestionsDataSource.cellIdentifier)
        tableView.register(LoadingDataSource.Cell.self, forCellReuseIdentifier: LoadingDataSource.cellIdentifier)
        tableView.register(FailureDataSource.Cell.self, forCellReuseIdentifier: FailureDataSource.cellIdentifier)
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.separatorColor = .divider
        reloadTableData()

        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .none
        textView.font = WPStyleGuide.tableviewTextFont()
        textView.textColor = .text
        textView.isScrollEnabled = false
        // Padding already provided by readable margins
        // Don't add extra padding so text aligns with suggestions
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 11, left: 0, bottom: 11, right: 0)
        textView.accessibilityLabel = NSLocalizedString("Add new tags, separated by commas.", comment: "Voiceover accessibility label for the tags field in blog post settings.")
        textView.accessibilityIdentifier = "add-tags"

        view.addSubview(tableView)
        textViewContainer.addSubview(textView)
        view.addSubview(textViewContainer)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textViewContainer.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),

            textViewContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 35),
            textViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -1),
            textViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 1),
            textViewContainer.bottomAnchor.constraint(equalTo: tableView.topAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

        textViewContainer.backgroundColor = .basicBackground
        textViewContainer.layer.borderColor = UIColor.divider.cgColor
        textViewContainer.layer.borderWidth = .hairlineBorderWidth
        textViewContainer.layer.masksToBounds = false

        keyboardObserver.tableView = tableView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateSuggestions()
        textView.becomeFirstResponder()
        loadTags()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let tags = allTags

        if originalTags != tags {
            onValueChanged?(tags.joined(separator: ", "))
        }
        WPError.dismissNetworkingNotice()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *) {
            textViewContainer.layer.borderColor = UIColor.divider.cgColor
        }
    }

    fileprivate func reloadTableData() {
        tableView.reloadData()
    }
}


// MARK: - Tags Loading

private extension PostTagPickerViewController {
    func loadTags() {
        dataSource = LoadingDataSource()
        let context = ContextManager.sharedInstance().mainContext
        let service = PostTagService(managedObjectContext: context)
        service.getTopTags(
            for: blog,
            success: { [weak self] tags in
                let tagNames = tags.compactMap { return $0.name }
                self?.tagsLoaded(tags: tagNames)
            },
            failure: { [weak self] error in
                self?.tagsFailedLoading(error: error)
            }
        )
    }

    func tagsLoaded(tags: [String]) {
        dataSource = SuggestionsDataSource(suggestions: tags,
                                           selectedTags: completeTags,
                                           searchQuery: partialTag)
    }

    func tagsFailedLoading(error: Error) {
        DDLogError("Error loading tags for \(String(describing: blog.url)): \(error)")
        dataSource = FailureDataSource()
        WPError.showNetworkingNotice(title: NSLocalizedString("Couldn't load tags.", comment: "Error message when tag loading failed"), error: error as NSError)
    }
}

// MARK: - Tag tokenization

/*
 There are two different "views" of the tag list:

 1. For completion purposes, everything before the last comma is a "completed"
    tag, and will not appear again in suggestions. The text after the last comma
    (or the whole text if there is no comma) will be interpreted as a partially
    typed tag (parialTag) and used to filter suggestions.

 2. The above doesn't apply when it comes to reporting back the tag list, and so
    we use `allTags` for all the tags in the text view. In this case the last
    part of text is considered as a complete tag as well.

 */
private extension PostTagPickerViewController {
    static func extractTags(from string: String) -> [String] {
        return string.components(separatedBy: ",")
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    }

    var tagsInField: [String] {
        return PostTagPickerViewController.extractTags(from: textView.text)
    }

    var partialTag: String {
        return tagsInField.last ?? ""
    }

    var completeTags: [String] {
        return Array(tagsInField.dropLast())
    }

    var allTags: [String] {
        return tagsInField.filter({ !$0.isEmpty })
    }

    func complete(tag: String) {
        var tags = completeTags
        tags.append(tag)
        tags.append("")
        textView.text = tags.joined(separator: ", ")
        updateSuggestions()
    }
}

// MARK: - Text & Input Handling

extension PostTagPickerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard textView.markedTextRange == nil else {
            // Don't try to normalize if we're still in multistage input
            return
        }
        normalizeText()
        updateSuggestions()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let original = textView.text as NSString
        if range.length == 0,
            range.location == original.length,
            text == ",",
            partialTag.isEmpty {
            // Don't allow a second comma if the last tag is blank
            return false
        } else if
            range.length == 1 && text == "", // Deleting last character
            range.location > 0, // Not at the beginning
            range.location + range.length == original.length, // At the end
            original.substring(with: NSRange(location: range.location - 1, length: 1)) == "," // Previous is a comma
        {
            // Delete the comma as well
            textView.text = original.substring(to: range.location - 1) + original.substring(from: range.location + range.length)
            textView.selectedRange = NSRange(location: range.location - 1, length: 0)
            textViewDidChange(textView)
            return false
        } else if range.length == 0, // Inserting
            text == ",", // a comma
            range.location == original.length // at the end
        {
            // Append a space
            textView.text = original.replacingCharacters(in: range, with: ", ")
            textViewDidChange(textView)
            return false
        } else if text == "\n", // return
            range.location == original.length, // at the end
            !partialTag.isEmpty // with some (partial) tag typed
        {
            textView.text = original.replacingCharacters(in: range, with: ", ")
            textViewDidChange(textView)
            return false
        } else if text == "\n" // return anywhere else
            {
                return false
        }
        return true
    }

    fileprivate func normalizeText() {
        // Remove any space before a comma, and allow one space at most after.
        let regexp = try! NSRegularExpression(pattern: "\\s*(,(\\s|(\\s(?=\\s)))?)\\s*", options: [])
        let text = textView.text ?? ""
        let range = NSRange(location: 0, length: (text as NSString).length)
        textView.text = regexp.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
    }

    /// Normalize tags for initial set up.
    ///
    /// The algorithm here differs slightly as we don't want to interpret the last tag as a partial one.
    ///
    fileprivate func normalizeInitialTags(tags: [String]) -> String {
        var tags = tags.filter({ !$0.isEmpty })
        tags.append("")
        return tags.joined(separator: ", ")
    }

    fileprivate func updateSuggestions() {
        dataSource.selectedTags = completeTags
        dataSource.searchQuery = partialTag
        reloadTableData()
    }
}

extension PostTagPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch tableView.dataSource {
        case is FailureDataSource:
            loadTags()
        case is LoadingDataSource:
            return
        case is SuggestionsDataSource:
            suggestionTapped(cell: tableView.cellForRow(at: indexPath))
        default:
            assertionFailure("Unexpected data source")
        }
    }

    private func suggestionTapped(cell: UITableViewCell?) {
        guard let tag = cell?.textLabel?.text else {
            return
        }
        complete(tag: tag)
    }
}

// MARK: - Data Sources

private protocol PostTagPickerDataSource: UITableViewDataSource {
    var selectedTags: [String] { get set }
    var searchQuery: String { get set }
}

private class LoadingDataSource: NSObject, PostTagPickerDataSource {
    @objc var selectedTags = [String]()
    @objc var searchQuery = ""

    @objc static let cellIdentifier = "Loading"
    typealias Cell = UITableViewCell

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LoadingDataSource.cellIdentifier, for: indexPath)
        WPStyleGuide.configureTableViewSuggestionCell(cell)
        cell.textLabel?.text = NSLocalizedString("Loading...", comment: "Loading tags")
        cell.selectionStyle = .none
        return cell
    }
}

private class FailureDataSource: NSObject, PostTagPickerDataSource {
    @objc var selectedTags = [String]()
    @objc var searchQuery = ""

    @objc static let cellIdentifier = "Failure"
    typealias Cell = UITableViewCell

    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FailureDataSource.cellIdentifier, for: indexPath)
        WPStyleGuide.configureTableViewSuggestionCell(cell)
        return cell
    }
}

private class SuggestionsDataSource: NSObject, PostTagPickerDataSource {
    @objc static let cellIdentifier = "Default"
    @objc let suggestions: [String]

    @objc init(suggestions: [String], selectedTags: [String], searchQuery: String) {
        self.suggestions = suggestions
        self.selectedTags = selectedTags
        self.searchQuery = searchQuery
        super.init()
    }

    @objc var selectedTags: [String]
    @objc var searchQuery: String

    @objc var availableSuggestions: [String] {
        return suggestions.filter({ !selectedTags.contains($0) })
    }

    @objc var matchedSuggestions: [String] {
        guard !searchQuery.isEmpty else {
            return availableSuggestions
        }
        return availableSuggestions.filter({ $0.localizedStandardContains(searchQuery) })
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchedSuggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SuggestionsDataSource.cellIdentifier, for: indexPath)
        WPStyleGuide.configureTableViewSuggestionCell(cell)
        let match = matchedSuggestions[indexPath.row]
        cell.textLabel?.attributedText = highlight(searchQuery, in: match)
        return cell
    }

    @objc func highlight(_ search: String, in string: String) -> NSAttributedString {
        let highlighted = NSMutableAttributedString(string: string)
        let range = (string as NSString).localizedStandardRange(of: search)
        guard range.location != NSNotFound else {
            return highlighted
        }
        let font = UIFont.systemFont(ofSize: WPStyleGuide.tableviewTextFont().pointSize, weight: .bold)
        highlighted.setAttributes([.font: font], range: range)
        return highlighted
    }
}

// MARK: - Style

extension WPStyleGuide {
    @objc static func configureTableViewSuggestionCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)
        cell.textLabel?.textColor = .text
        cell.backgroundColor = .listForeground
    }
}
