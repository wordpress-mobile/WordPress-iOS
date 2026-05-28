import Foundation
import GutenbergKit
import Pulse
import Support

extension GutenbergKit.EditorViewControllerDelegate {
    func editor(_ viewController: GutenbergKit.EditorViewController, didLogNetworkRequest request: GutenbergKit.RecordedNetworkRequest) {
        guard ExtensiveLogging.enabled, let url = URL(string: request.url) else {
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.allHTTPHeaderFields = request.requestHeaders
        urlRequest.httpBody = request.requestBody?.data(using: .utf8)

        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: request.status,
            httpVersion: nil,
            headerFields: request.responseHeaders
        )

        LoggerStore.shared.storeRequest(
            urlRequest,
            response: httpResponse,
            error: nil,
            data: request.responseBody?.data(using: .utf8)
        )
    }
}

private func getLocalizedString(for value: GutenbergKit.EditorLocalizableString) -> String {
    switch value {
    case .showMore: NSLocalizedString("editor.blockInserter.showMore", value: "Show More", comment: "Button title to expand and show more blocks")
    case .showLess: NSLocalizedString("editor.blockInserter.showLess", value: "Show Less", comment: "Button title to collapse and show fewer blocks")
    case .search: NSLocalizedString("editor.blockInserter.search", value: "Search", comment: "Placeholder text for block search field")
    case .insertBlock: NSLocalizedString("editor.blockInserter.insertBlock", value: "Insert Block", comment: "Context menu action to insert a block")
    case .failedToInsertMedia: NSLocalizedString("editor.media.failedToInsert", value: "Failed to insert media", comment: "Error message when media insertion fails")
    case .patterns: NSLocalizedString("editor.patterns.title", value: "Patterns", comment: "Navigation title for patterns view")
    case .noPatternsFound: NSLocalizedString("editor.patterns.noPatternsFound", value: "No Patterns Found", comment: "Title shown when no patterns match the search")
    case .insertPattern: NSLocalizedString("editor.patterns.insertPattern", value: "Insert Pattern", comment: "Context menu action to insert a pattern")
    case .patternsCategoryUncategorized: NSLocalizedString("editor.patterns.uncategorized", value: "Uncategorized", comment: "Category name for patterns without a category")
    case .patternsCategoryAll: NSLocalizedString("editor.patterns.all", value: "All", comment: "Category name for section showing all patterns")
    case .loadingEditor: NSLocalizedString("editor.loading.title", value: "Loading Editor", comment: "Text shown while the editor is loading")
    case .editorError: NSLocalizedString("editor.error.title", value: "Editor Error", comment: "Title shown when the editor encounters an error")
    }
}

extension EditorLocalizableString {
    var localized: String {
        getLocalizedString(for: self)
    }
}
