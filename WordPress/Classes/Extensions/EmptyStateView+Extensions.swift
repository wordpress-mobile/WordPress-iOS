import Foundation
import SwiftUI
import WordPressUI

extension EmptyStateView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == EmptyView {
    static func search() -> Self {
        EmptyStateView(
            NSLocalizedString("emptyStateView.noSearchResult.title", value: "No Results", comment: "Shared empty state view"),
            systemImage: "magnifyingglass",
            description: NSLocalizedString("emptyStateView.noSearchResult.description", value: "Try a new search", comment: "Shared empty state view")
        )
    }
}

extension EmptyStateView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == Button<Text> {
    static func failure(error: Error, onRetry: @escaping () -> Void) -> Self {
        EmptyStateView {
            Label(SharedStrings.Error.generic, systemImage: "exclamationmark.circle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button(SharedStrings.Button.retry, action: onRetry)
        }
    }
}
