import Foundation
import CocoaLumberjack
import WordPressShared

class ShareTagsPickerViewController: UIViewController {

    // MARK: - Public Properties

    @objc var onValueChanged: ((String) -> Void)?

    // MARK: - Private Properties

    /// Tags originally passed into init()
    ///
    fileprivate let originalTags: [String]

    /// SiteID to fetch tags for
    ///
    fileprivate let siteID: Int

    /// Apply Bar Button
    ///
    fileprivate lazy var applyButton: UIBarButtonItem = {
        let applyTitle = NSLocalizedString("Apply", comment: "Apply action on the app extension tags picker screen. Saves the selected tags for the post.")
        let button = UIBarButtonItem(title: applyTitle, style: .plain, target: self, action: #selector(applyWasPressed))
        button.accessibilityIdentifier = "Apply Button"
        return button
    }()

    /// Cancel Bar Button
    ///
    fileprivate lazy var cancelButton: UIBarButtonItem = {
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel action on the app extension tags picker screen.")
        let button = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelWasPressed))
        button.accessibilityIdentifier = "Cancel Button"
        return button
    }()

    @objc fileprivate let keyboardObserver = TableViewKeyboardObserver()
    fileprivate let textView = UITextView()
    fileprivate let textViewContainer = UIView()
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)
    fileprivate var dataSource: PostTagPickerDataSource = LoadingDataSource() {
        didSet {
            tableView.dataSource = dataSource
            reloadTableData()
        }
    }

    // MARK: - Initializers

    init(siteID: Int, tags: String?) {
        self.originalTags = tags?.arrayOfTags() ?? []
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
        textView.text = normalizeInitialTags(tags: originalTags)
        textViewDidChange(textView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize Interface
        setupNavigationBar()
        setupTableView()
        setupTextView()
        setupConstraints()
        keyboardObserver.tableView = tableView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateSuggestions()
        textView.becomeFirstResponder()
        loadTags()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.stopEditing()
        })
    }

    // MARK: - Setup Helpers

    fileprivate func setupNavigationBar() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = applyButton
    }

    fileprivate func setupTableView() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: SuggestionsDataSource.cellIdentifier)
        tableView.register(LoadingDataSource.Cell.self, forCellReuseIdentifier: LoadingDataSource.cellIdentifier)
        tableView.register(FailureDataSource.Cell.self, forCellReuseIdentifier: FailureDataSource.cellIdentifier)
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        reloadTableData()
    }

    fileprivate func setupTextView() {
        textView.delegate = self
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .none
        textView.font = WPStyleGuide.tableviewTextFont()
        textView.textColor = .neutral(.shade70)
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: Constants.textViewTopBottomInset, left: 0, bottom: Constants.textViewTopBottomInset, right: 0)
        textViewContainer.backgroundColor = UIColor(light: .white, dark: .listBackground)
        textViewContainer.layer.masksToBounds = false
    }

    fileprivate func setupConstraints() {
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

            textViewContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            textViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.textContainerLeadingConstant),
            textViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: Constants.textContainerTrailingConstant),
            textViewContainer.bottomAnchor.constraint(equalTo: tableView.topAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
    }
}

// MARK: - Actions

extension ShareTagsPickerViewController {
    @objc func cancelWasPressed() {
         stopEditing()
        _ = navigationController?.popViewController(animated: true)
    }

    @objc func applyWasPressed() {
        stopEditing()
        let tags = allTags
        if originalTags != tags {
            onValueChanged?(tags.joined(separator: ", "))
        }
        _ = navigationController?.popViewController(animated: true)
    }

    func suggestionTapped(cell: UITableViewCell?) {
        guard let tag = cell?.textLabel?.text else {
            return
        }
        complete(tag: tag)
    }
}

// MARK: - Tags Loading

fileprivate extension ShareTagsPickerViewController {
    func loadTags() {
        dataSource = LoadingDataSource()
        let service = AppExtensionsService()
        service.fetchTopTagsForSite(siteID, onSuccess: { tags in
            let tagNames = tags.compactMap { return $0.name }
            self.tagsLoaded(tags: tagNames)
        }) { error in
            self.tagsFailedLoading(error: error)
        }
    }

    func tagsLoaded(tags: [String]) {
        dataSource = SuggestionsDataSource(suggestions: tags,
                                           selectedTags: completeTags,
                                           searchQuery: partialTag)
    }

    func tagsFailedLoading(error: Error?) {
        if let error = error {
            DDLogError("Error loading tags: \(error)")
        }
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
private extension ShareTagsPickerViewController {
    var tagsInField: [String] {
        return textView.text.arrayOfTags()
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

extension ShareTagsPickerViewController: UITextViewDelegate {
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

    func updateSuggestions() {
        dataSource.selectedTags = completeTags
        dataSource.searchQuery = partialTag
        reloadTableData()
    }
}

// MARK: - UITableView Delegate Conformance

extension ShareTagsPickerViewController: UITableViewDelegate {
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
}

// MARK: - Misc private helpers

fileprivate extension ShareTagsPickerViewController {
    func stopEditing() {
        view.endEditing(true)
        resetPresentationViewUsingKeyboardFrame()
    }

    func resetPresentationViewUsingKeyboardFrame(_ keyboardFrame: CGRect = .zero) {
        guard let presentationController = navigationController?.presentationController as? ExtensionPresentationController else {
            return
        }
        presentationController.resetViewUsingKeyboardFrame(keyboardFrame)
    }

    func reloadTableData() {
        tableView.reloadData()
        textViewContainer.layer.shadowOpacity = tableView.isEmpty ? 0 : 0.5
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
        WPStyleGuide.Share.configureLoadingTagCell(cell)
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
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FailureDataSource.cellIdentifier, for: indexPath)
        WPStyleGuide.Share.configureLoadingTagCell(cell)
        cell.textLabel?.text = NSLocalizedString("Couldn't load tags. Tap to retry.", comment: "Error message when tag loading failed")
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
        WPStyleGuide.Share.configureTagCell(cell)
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

// MARK: - Constants

extension ShareTagsPickerViewController {
    struct Constants {
        static let textViewTopBottomInset: CGFloat = 11.0
        static let textContainerLeadingConstant: CGFloat = -1
        static let textContainerTrailingConstant: CGFloat = 1
    }
}
