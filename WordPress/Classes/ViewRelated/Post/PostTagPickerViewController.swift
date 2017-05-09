import Foundation
import WordPressShared

class PostTagPickerViewController: UIViewController {
    private let originalTags: [String]
    var onValueChanged: ((String) -> Void)?
    let blog: Blog
    let keyboardObserver = TableViewKeyboardObserver()

    init(tags: String, blog: Blog) {
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
    private let shadow = ShadowView()
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)
    fileprivate var dataSource: PostTagPickerDataSource = LoadingDataSource() {
        didSet {
            tableView.dataSource = dataSource
            reloadTableData()
        }
    }
    private lazy var textContainerHeightConstraint: NSLayoutConstraint = {
        return self.textViewContainer.heightAnchor.constraint(equalToConstant: 44)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        textView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: SuggestionsDataSource.cellIdentifier)
        tableView.register(LoadingDataSource.Cell.self, forCellReuseIdentifier: LoadingDataSource.cellIdentifier)
        tableView.register(FailureDataSource.Cell.self, forCellReuseIdentifier: FailureDataSource.cellIdentifier)
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        reloadTableData()

        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.font = WPStyleGuide.tableviewTextFont()
        textView.textColor = WPStyleGuide.darkGrey()
        textView.isScrollEnabled = false


        textViewContainer.addSubview(textView)
        view.addSubview(textViewContainer)
        view.addSubview(tableView)
        view.addSubview(shadow)

        shadow.tintColor = WPStyleGuide.greyDarken30()

        textView.translatesAutoresizingMaskIntoConstraints = false
        textViewContainer.translatesAutoresizingMaskIntoConstraints = false
        shadow.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),

            textViewContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 35),
            textContainerHeightConstraint,
            textViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -1),
            textViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 1),

            textViewContainer.bottomAnchor.constraint(equalTo: tableView.topAnchor),

            shadow.topAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
            shadow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadow.heightAnchor.constraint(equalToConstant: 3.5),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        updateTextViewHeight()

        textViewContainer.backgroundColor = UIColor.white
        textViewContainer.layer.borderColor = WPStyleGuide.greyLighten20().cgColor
        textViewContainer.layer.borderWidth = 0.5

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
    }

    fileprivate func updateTextViewHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        textContainerHeightConstraint.constant = max(size.height, 44)
    }

    fileprivate func reloadTableData() {
        tableView.reloadData()
        shadow.isHidden = tableView.isEmpty
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
                self?.tagsLoaded(tags: tags)
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
        DDLogSwift.logError("Error loading tags for \(String(describing: blog.url)): \(error)")
        dataSource = FailureDataSource()
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
        updateTextViewHeight()
        updateSuggestions()
    }
}

// MARK: - Text & Input Handling

extension PostTagPickerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        normalizeText()
        updateTextViewHeight()
        updateSuggestions()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let original = textView.text as NSString
        if range.length == 0,
            text == ",",
            partialTag.isEmpty {
            // Don't allow a second comma if the last tag is blank
            return false
        } else if
            range.length == 1 && text == "", // Deleting last character
            range.location > 0, // Not at the beginning
            original.substring(with: NSRange(location: range.location - 1, length: 1)) == "," // Previous is a comma
        {
            // Delete the comma as well
            textView.text = original.substring(to: range.location - 1)
            return false
        } else if range.length == 0, // Inserting
            text == ",", // a comma
            range.location == original.length // at the end
        {
            // Append a space
            textView.text = original.replacingCharacters(in: range, with: ", ")
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
    var selectedTags = [String]()
    var searchQuery = ""

    static let cellIdentifier = "Loading"
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
    var selectedTags = [String]()
    var searchQuery = ""

    static let cellIdentifier = "Failure"
    typealias Cell = UITableViewCell

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FailureDataSource.cellIdentifier, for: indexPath)
        WPStyleGuide.configureTableViewSuggestionCell(cell)
        cell.textLabel?.text = NSLocalizedString("Couldn't load tags. Tap to retry.", comment: "Error message when tag loading failed")
        return cell
    }
}

private class SuggestionsDataSource: NSObject, PostTagPickerDataSource {
    static let cellIdentifier = "Default"
    let suggestions: [String]

    init(suggestions: [String], selectedTags: [String], searchQuery: String) {
        self.suggestions = suggestions
        self.selectedTags = selectedTags
        self.searchQuery = searchQuery
        super.init()
    }

    var selectedTags: [String]
    var searchQuery: String

    var availableSuggestions: [String] {
        return suggestions.filter({ !selectedTags.contains($0) })
    }

    var matchedSuggestions: [String] {
        guard !searchQuery.isEmpty else {
            return availableSuggestions
        }
        return availableSuggestions.filter({ $0.localizedCaseInsensitiveContains(searchQuery) })
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
        cell.textLabel?.text = matchedSuggestions[indexPath.row]
        return cell
    }
}

// MARK: - Style

extension WPStyleGuide {
    static func configureTableViewSuggestionCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)
        cell.textLabel?.textColor = WPStyleGuide.greyDarken30()
        cell.backgroundColor = WPStyleGuide.greyLighten30()
    }
}
