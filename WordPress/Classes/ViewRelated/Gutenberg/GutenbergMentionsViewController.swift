import Foundation
import UIKit

public class GutenbergMentionsViewController: UIViewController {

    static let mentionTriggerText = String("@")

    public lazy var backgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .listForeground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public lazy var separatorView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.divider
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(light: UIColor.colorFromHex("e9eff3"), dark: UIColor.colorFromHex("2e2e2e"))
        return view
    }()

    public lazy var searchView: UITextField = {
        let textField = UITextField(frame: CGRect.zero)
        textField.placeholder = NSLocalizedString("Search users...", comment: "Placeholder message when showing mentions search field")
        textField.text = Self.mentionTriggerText
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.textColor = .text
        return textField
    }()

    public lazy var suggestionsView: SuggestionsTableView = {
        let suggestionsView = SuggestionsTableView()
        suggestionsView.animateWithKeyboard = false
        suggestionsView.enabled = true
        suggestionsView.showLoading = true
        suggestionsView.showSuggestions(forWord: Self.mentionTriggerText)
        suggestionsView.suggestionsDelegate = self
        suggestionsView.translatesAutoresizingMaskIntoConstraints = false
        suggestionsView.siteID = siteID
        suggestionsView.useTransparentHeader = false
        return suggestionsView
    }()

    private let siteID: NSNumber
    public var onCompletion: ((Result<String, NSError>) -> Void)?

    public init(siteID: NSNumber) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        let toolbarSize = CGFloat(44)

        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            backgroundView.heightAnchor.constraint(equalToConstant: toolbarSize)
        ])

        let margin = CGFloat(10)
        view.addSubview(searchView)
        searchView.becomeFirstResponder()
        NSLayoutConstraint.activate([
            searchView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: margin),
            searchView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -margin),
            searchView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            searchView.heightAnchor.constraint(equalToConstant: toolbarSize)
        ])

        view.addSubview(suggestionsView)
        NSLayoutConstraint.activate([
            suggestionsView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 0),
            suggestionsView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: 0),
            suggestionsView.bottomAnchor.constraint(equalTo: searchView.topAnchor),
            suggestionsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])

        view.addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: backgroundView.topAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0)
        ])

        view.setNeedsUpdateConstraints()
    }

    override public func viewDidAppear(_ animated: Bool) {
        suggestionsView.showSuggestions(forWord: Self.mentionTriggerText)
    }
}

extension GutenbergMentionsViewController: UITextFieldDelegate {

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
            // We are dispatching this async to allow this delegate to finish and process the keypress before executing the cancelation.
            DispatchQueue.main.async {
                self.onCompletion?(.failure(self.buildErrorForCancelation()))
            }
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
        if let suggestion = suggestion {
            onCompletion?(.success(suggestion))
        }
    }

    public func suggestionsTableView(_ suggestionsTableView: SuggestionsTableView, didChangeTableBounds bounds: CGRect) {

    }

    public func suggestionsTableViewMaxDisplayedRows(_ suggestionsTableView: SuggestionsTableView) -> Int {
        return 7
    }

    public func suggestionsTableViewDidTapHeader(_ suggestionsTableView: SuggestionsTableView) {
        onCompletion?(.failure(buildErrorForCancelation()))
    }
}

extension GutenbergMentionsViewController {

    enum MentionError: CustomNSError {
        case canceled
        case notAvailable

        static var errorDomain: String = "MentionErrorDomain"

        var errorCode: Int {
            switch self {
            case .canceled:
                return 1
            case .notAvailable:
                return 2
            }
        }

        var errorUserInfo: [String: Any] {
            return [:]
        }
    }

    private func buildErrorForCancelation() -> NSError {
        return MentionError.canceled as NSError
    }
}
