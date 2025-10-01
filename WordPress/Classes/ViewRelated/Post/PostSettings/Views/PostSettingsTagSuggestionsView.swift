import SwiftUI
import WordPressUI

struct PostSettingsTagSuggestionsView: View {
    let suggestions: [String]
    let onSelection: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ScaledImage("sparkle", height: 14)
                Text(Strings.suggestionsLabel)
            }
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { tag in
                        SuggestedTagButton(tag: tag) {
                            onSelection(tag)
                        }
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}

private struct SuggestedTagButton: View {
    let tag: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(EdgeInsets(top: 7, leading: 12, bottom: 9, trailing: 12))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(.secondaryLabel).opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
        }
        .buttonStyle(.plain)
    }
}

private enum Strings {
    static let suggestionsLabel = NSLocalizedString(
        "postSettings.tags.suggestions",
        value: "Suggested Tags",
        comment: "Label for the tag suggestions section."
    )
}

#Preview {
    PostSettingsTagSuggestionsView(suggestions: ["swift", "ios"]) {
        print("selected", $0)
    }
}
