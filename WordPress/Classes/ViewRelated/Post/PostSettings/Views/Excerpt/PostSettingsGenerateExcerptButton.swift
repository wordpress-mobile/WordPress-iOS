import SwiftUI
import WordPressUI
import DesignSystem

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26, *)
struct PostSettingsGenerateExcerptButton: View {
    let content: String
    let onSelection: (String) -> Void

    @State private var isShowingExcerptGenerator = false

    var onWillShowPopover: (() -> Void)?

    var body: some View {
        // Show the Generate button
        Button {
            onWillShowPopover?()
            isShowingExcerptGenerator = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                    .font(.caption2)
                Text(Strings.generateButton)
            }
        }
        .popover(isPresented: $isShowingExcerptGenerator) {
            popover
        }
    }

    @ViewBuilder
    private var popover: some View {
        NavigationView {
            Group {
                switch SystemLanguageModel.default.availability {
                case .available:
                    PostSettingsGenerateExcerptView(
                        postContent: content,
                        onSelection: { selectedText in
                            onSelection(selectedText)
                            isShowingExcerptGenerator = false
                        }
                    )
                case .unavailable(let reason):
                    LanguageModelUnavailableView(reason: reason)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button.make(role: .cancel) {
                        isShowingExcerptGenerator = false
                    }
                }
            }
        }
        .frame(maxWidth: 420, minHeight: 500)
    }
}

private enum Strings {
    static let generateButton = NSLocalizedString(
        "postSettings.excerpt.generateButton",
        value: "Generate",
        comment: "Button to generate an excerpt using AI"
    )

    static let generateExcerptTitle = NSLocalizedString(
        "postSettings.excerpt.generator.title",
        value: "Generate Excerpt",
        comment: "Title for the excerpt generator popover"
    )
}
