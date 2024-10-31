import CoreData

protocol FullScreenCommentReplyViewModelType {
    var suggestionsService: SuggestionService { get }
    var context: NSManagedObjectContext { get }
    func suggestionsTableView(with siteID: NSNumber, useTransparentHeader: Bool, prominentSuggestionsIds: [NSNumber]?, delegate: SuggestionsTableViewDelegate) -> SuggestionsTableView
    func shouldShowSuggestions(with siteID: NSNumber?) -> Bool
}

struct FullScreenCommentReplyViewModel: FullScreenCommentReplyViewModelType {
    var suggestionsService: SuggestionService
    var context: NSManagedObjectContext

    init(suggestionsService: SuggestionService = SuggestionService.shared, context: NSManagedObjectContext = ContextManager.shared.mainContext) {
        self.suggestionsService = suggestionsService
        self.context = context
    }

    func suggestionsTableView(with siteID: NSNumber, useTransparentHeader: Bool, prominentSuggestionsIds: [NSNumber]?, delegate: SuggestionsTableViewDelegate) -> SuggestionsTableView {
        let suggestionListViewModel = SuggestionsListViewModel(siteID: siteID, context: context)
        suggestionListViewModel.userSuggestionService = suggestionsService
        suggestionListViewModel.suggestionType = .mention
        let tableView = SuggestionsTableView(viewModel: suggestionListViewModel, delegate: delegate)
        tableView.useTransparentHeader = useTransparentHeader
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.prominentSuggestionsIds = prominentSuggestionsIds
        return tableView
    }

    func shouldShowSuggestions(with siteID: NSNumber?) -> Bool {
        guard let siteID = siteID,
              let blog = Blog.lookup(withID: siteID, in: context) else {
                  return false
              }

        return suggestionsService.shouldShowSuggestions(for: blog)
    }
}
