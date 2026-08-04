import Foundation
import GutenbergKit
import Support

extension GutenbergKit.EditorViewControllerDelegate {
    func editor(
        _ viewController: GutenbergKit.EditorViewController,
        didLogNetworkRequest request: GutenbergKit.RecordedNetworkRequest
    ) {
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

        PulseNetworkLogger.shared
            .storeRequest(
                urlRequest,
                response: httpResponse,
                error: nil,
                data: request.responseBody?.data(using: .utf8)
            )
    }
}

private func getLocalizedString(for value: GutenbergKit.EditorLocalizableString) -> String? {
    switch value {
    case .showMore:
        NSLocalizedString(
            "editor.blockInserter.showMore",
            value: "Show More",
            comment: "Button title to expand and show more blocks"
        )
    case .showLess:
        NSLocalizedString(
            "editor.blockInserter.showLess",
            value: "Show Less",
            comment: "Button title to collapse and show fewer blocks"
        )
    case .search:
        NSLocalizedString(
            "editor.blockInserter.search",
            value: "Search",
            comment: "Placeholder text for block search field"
        )
    case .insertBlock:
        NSLocalizedString(
            "editor.blockInserter.insertBlock",
            value: "Insert Block",
            comment: "Context menu action to insert a block"
        )
    case .failedToInsertMedia:
        NSLocalizedString(
            "editor.media.failedToInsert",
            value: "Failed to insert media",
            comment: "Error message when media insertion fails"
        )
    case .patterns:
        NSLocalizedString("editor.patterns.title", value: "Patterns", comment: "Navigation title for patterns view")
    case .noPatternsFound:
        NSLocalizedString(
            "editor.patterns.noPatternsFound",
            value: "No Patterns Found",
            comment: "Title shown when no patterns match the search"
        )
    case .insertPattern:
        NSLocalizedString(
            "editor.patterns.insertPattern",
            value: "Insert Pattern",
            comment: "Context menu action to insert a pattern"
        )
    case .patternsCategoryUncategorized:
        NSLocalizedString(
            "editor.patterns.uncategorized",
            value: "Uncategorized",
            comment: "Category name for patterns without a category"
        )
    case .patternsCategoryAll:
        NSLocalizedString(
            "editor.patterns.all",
            value: "All",
            comment: "Category name for section showing all patterns"
        )
    case .patternsCount(let count):
        if count == 1 {
            NSLocalizedString(
                "editor.patterns.count.singular",
                value: "1 pattern",
                comment: "Singular label displaying the number of patterns in a category"
            )
        } else {
            String(
                format: NSLocalizedString(
                    "editor.patterns.count.plural",
                    value: "%1$d patterns",
                    comment:
                        "Plural label displaying the number of patterns in a category. %1$d is a placeholder for the number of patterns."
                ),
                count
            )
        }
    case .loadingEditor:
        NSLocalizedString(
            "editor.loading.title",
            value: "Loading Editor",
            comment: "Text shown while the editor is loading"
        )
    case .editorError:
        NSLocalizedString(
            "editor.error.title",
            value: "Editor Error",
            comment: "Title shown when the editor encounters an error"
        )
    case .lockdownModeTitle:
        NSLocalizedString(
            "editor.lockdownMode.title",
            value: "Lockdown Mode Detected",
            comment: "Title shown when Lockdown Mode may affect the editor"
        )
    case .lockdownModeWarning:
        NSLocalizedString(
            "editor.lockdownMode.warning",
            value: "Lockdown Mode is enabled. The editor may not work correctly.",
            comment: "Warning shown when Lockdown Mode may affect the editor"
        )
    case .lockdownModeExcludeHint:
        NSLocalizedString(
            "editor.lockdownMode.excludeHint",
            value:
                "You can exclude this app from Lockdown Mode in Settings, then re-open the editor to restore full functionality.",
            comment: "Instructions for excluding the app from Lockdown Mode"
        )
    case .lockdownModeLearnMore:
        NSLocalizedString(
            "editor.lockdownMode.learnMore",
            value: "Learn More",
            comment: "Button title to learn more about Lockdown Mode"
        )
    case .lockdownModeDismiss:
        NSLocalizedString(
            "editor.lockdownMode.dismiss",
            value: "Dismiss",
            comment: "Button title to dismiss the Lockdown Mode warning"
        )
    // Declining a key lets the editor render its own string, so strings added
    // by a newer GutenbergKit appear in English rather than breaking this build.
    // `@unknown` because a plain `default` warns that it will never execute
    // while this switch happens to cover every case.
    @unknown default:
        nil
    }
}

extension EditorLocalizableString {
    var localized: String? {
        getLocalizedString(for: self)
    }
}
