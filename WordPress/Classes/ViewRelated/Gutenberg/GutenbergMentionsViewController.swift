import Foundation
import UIKit

public class GutenbergMentionsViewController: UIViewController {

    static let mentionTriggerText = String("@")

    public lazy var backgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .basicBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public lazy var searchView: UITextField = {
        let textField = UITextField(frame: CGRect.zero)
        textField.placeholder = NSLocalizedString("Search users...", comment: "Placeholder message when showing mentions search field")
        textField.text = Self.mentionTriggerText
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()

    public lazy var suggestionsView: SuggestionsTableView = {
        let suggestionsView = SuggestionsTableView()
        suggestionsView.enabled = true
        suggestionsView.showSuggestions(forWord: Self.mentionTriggerText)
        suggestionsView.suggestionsDelegate = self
        suggestionsView.translatesAutoresizingMaskIntoConstraints = false
        suggestionsView.siteID = siteID
        suggestionsView.useTransparentHeader = true
        return suggestionsView
    }()

    deinit {
    }

    private let siteID: NSNumber
    public var onCompletion: ((Result<String, NSError>) -> Void)?

    public init(siteID: NSNumber) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.siteID = 0
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            backgroundView.heightAnchor.constraint(equalToConstant: 50.0)
        ])

        let margin = CGFloat(10)
        view.addSubview(searchView)
        searchView.becomeFirstResponder()
        NSLayoutConstraint.activate([
            searchView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            searchView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -margin),
            searchView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            searchView.heightAnchor.constraint(equalToConstant: 50.0)
        ])

        view.addSubview(suggestionsView)
        NSLayoutConstraint.activate([
            suggestionsView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            suggestionsView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -margin),
            suggestionsView.bottomAnchor.constraint(equalTo: searchView.topAnchor),
            suggestionsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])

        view.setNeedsUpdateConstraints()
    }

    override public func viewDidAppear(_ animated: Bool) {
        suggestionsView.showSuggestions(forWord: Self.mentionTriggerText)
    }
}

extension GutenbergMentionsViewController: UITextFieldDelegate {

    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        suggestionsView.showSuggestions(forWord: text)
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        onCompletion?(.failure(buildErrorForCancelation()))
        return true
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let nsString = textField.text as NSString? else {
            return true
        }
        let searchWord = nsString.replacingCharacters(in: range, with: string)
        if searchWord.hasPrefix(Self.mentionTriggerText) {
            suggestionsView.showSuggestions(forWord: searchWord)
        } else {
            onCompletion?(.failure(buildErrorForCancelation()))
        }
        return true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if suggestionsView.numberOfSuggestions() == 1 {
            suggestionsView.selectSuggestion(atPosition: 0)
        }
        return true
    }
}

extension GutenbergMentionsViewController: SuggestionsTableViewDelegate {

    public func suggestionsTableView(_ suggestionsTableView: SuggestionsTableView, didSelectSuggestion suggestion: String?, forSearchText text: String) {
        suggestionsTableView.showSuggestions(forWord: String())
        if let suggestion = suggestion {
            onCompletion?(.success(suggestion))
        }
    }

    public func suggestionsTableView(_ suggestionsTableView: SuggestionsTableView, didChangeTableBounds bounds: CGRect) {

    }

    public func suggestionsTableViewMaxDisplayedRows(_ suggestionsTableView: SuggestionsTableView) -> Int {
        return 3
    }

}

extension GutenbergMentionsViewController {

    private func buildErrorForCancelation() -> NSError {
        return NSError(domain: "MentionErrorDomain", code:1, userInfo: nil);
    }
}
