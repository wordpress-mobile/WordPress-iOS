import Foundation
import SwiftUI
import WordPressUI

extension EmptyStateView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == EmptyView {
    static func search() -> some View {
        VStack {
            EmptyStateView(
                NSLocalizedString("emptyStateView.noSearchResult.title", value: "No Results", comment: "Shared empty state view"),
                systemImage: "magnifyingglass",
                description: NSLocalizedString("emptyStateView.noSearchResult.description", value: "Try a new search", comment: "Shared empty state view")
            )      .padding(.top, 50)
            Spacer()
        }
    }
}
