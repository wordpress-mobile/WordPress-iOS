import SwiftUI
import WordPressUI
import DesignSystem
import FoundationModels

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
            HStack(spacing: 5) {
                ScaledImage("sparkle", height: 18)
                Text(Strings.generateButton)
            }
        }
        .sheet(isPresented: $isShowingExcerptGenerator) {
            form
        }
    }

    @ViewBuilder
    private var form: some View {
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
                    LanguageModelUnavailableView(reason: reason).onAppear {
                        WPAnalytics.track(WPAnalyticsEvent.intelligenceUnavailableViewShown)
                    }
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
