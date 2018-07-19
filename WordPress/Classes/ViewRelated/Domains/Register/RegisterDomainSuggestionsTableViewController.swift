import Foundation

class RegisterDomainSuggestionsTableViewController: DomainSuggestionsTableViewController {

    override open var suggestOnlyWordPressDotCom: Bool {
        return false
    }
    override open var useFadedColorForParentDomains: Bool {
        return false
    }
    override open var sectionTitle: String {
        return ""
    }
    override open var sectionDescription: String {
        return NSLocalizedString(
            "Pick an available address",
            comment: "Register domain - Suggested Domain description for the screen"
        )
    }
    override open var searchFieldPlaceholder: String {
        return NSLocalizedString(
            "Type to get more suggestions",
            comment: "Register domain - Search field placeholder for the Suggested Domain screen"
        )
    }
}
