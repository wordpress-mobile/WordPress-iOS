import Foundation

class SiteCreationDomainSuggestionsTableViewController: DomainSuggestionsTableViewController {

    override open var domainSuggestionType: DomainsServiceRemote.DomainSuggestionType {
        return .onlyWordPressDotCom
    }
    override open var useFadedColorForParentDomains: Bool {
        return true
    }
    override open var sectionTitle: String {
        return NSLocalizedString(
            "Step 4 of 4",
            comment: "Title for last step in the site creation process."
            ).localizedUppercase
    }
    override open var sectionDescription: String {
        return NSLocalizedString(
            "Pick an available \"yourname.wordpress.com\" address to let people find you on the web.",
            comment: "Description of how to pick a domain name during the site creation process"
        )
    }
    override open var searchFieldPlaceholder: String {
        return NSLocalizedString(
            "Type a keyword for more ideas",
            comment: "Placeholder text for domain search during site creation."
        )
    }
}
