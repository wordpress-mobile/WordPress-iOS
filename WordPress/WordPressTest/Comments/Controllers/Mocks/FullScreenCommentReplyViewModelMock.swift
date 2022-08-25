import Foundation

@testable import WordPress

struct FullScreenCommentReplyViewModelMock: FullScreenCommentReplyViewModelType {
    var suggestionsService: SuggestionService

    var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        self.suggestionsService = SuggestionServiceMock(context: context)
    }

    func suggestionsTableView(with siteID: NSNumber, useTransparentHeader: Bool, prominentSuggestionsIds: [NSNumber]?, delegate: SuggestionsTableViewDelegate) -> SuggestionsTableView {
        let blog = Blog(context: context)
        let suggestionListViewModel = SuggestionsListViewModel(blog: blog)
        suggestionListViewModel.context = context
        suggestionListViewModel.userSuggestionService = suggestionsService
        suggestionListViewModel.suggestionType = .mention
        let tableView = SuggestionsTableView(viewModel: suggestionListViewModel, delegate: delegate)
        tableView.prominentSuggestionsIds = prominentSuggestionsIds
        tableView.useTransparentHeader = useTransparentHeader
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }

    func shouldShowSuggestions(with siteID: NSNumber?) -> Bool {
        return true
    }
}
