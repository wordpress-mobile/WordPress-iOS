import Foundation

class RegisterDomainSuggestionsTableViewController: DomainSuggestionsTableViewController {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        domainSuggestionType = .noWordpressDotCom
    }

    override open var useFadedColorForParentDomains: Bool {
        return false
    }

    override open var searchFieldPlaceholder: String {
        return NSLocalizedString(
            "Type to get more suggestions",
            comment: "Register domain - Search field placeholder for the Suggested Domain screen"
        )
    }
}
