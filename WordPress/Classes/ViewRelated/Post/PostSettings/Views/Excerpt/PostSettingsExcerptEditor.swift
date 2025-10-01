import SwiftUI
import WordPressUI
import WordPressShared
import DesignSystem

struct PostSettingsExcerptEditor: View {
    let postContent: String

    @Binding var text: String

    @State private var wordCount = 0
    @State private var isAnimating = false
    @State private var textViewOpacity = 1.0
    @State private var showUndoButton = false
    @State private var previousText: String = ""
    @State private var hideUndoButtonTask: Task<Void, Never>?

    @FocusState private var isFocused: Bool

    @ScaledMetric private var editorHeightCompact = 160
    @ScaledMetric private var editorHeightRegular = 200

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let placeholder = PostSettingExcerptRow.localizedPlaceholderText

    var body: some View {
        Form {
            Section {
                editor
            } footer: {
                HStack {
                    Text(String.localizedStringWithFormat(Strings.characterCount, text.count))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String.localizedStringWithFormat(Strings.wordCount, wordCount))
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if FeatureFlag.intelligence.enabled && !postContent.isEmpty && LanguageModelHelper.isSupported {
                    if #available(iOS 26, *) {
                        PostSettingsGenerateExcerptButton(
                            content: postContent,
                            onSelection: { newText in
                                onGeneratedExcerptSelected(newText)
                            }
                        ) {
                            // A workaround for TextEditor regaining focus when
                            // the user interacts with Menu in the modal
                            isFocused = false
                        }
                    }
                }
            }
        }
        .onAppear {
            // Delay to ensure smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                isFocused = true
            }
            // Initial word count
            wordCount = text.wordCount
        }
        .onChange(of: text) { newValue in
            // Debounce word count calculation
            Task {
                try await Task.sleep(for: .milliseconds(330))
                self.wordCount = newValue.wordCount
            }
        }
    }

    private var editor: some View {
        TextEditor(text: $text)
            .focused($isFocused)
            .frame(minHeight: horizontalSizeClass == .compact ? editorHeightCompact : editorHeightRegular)
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(LinearGradient(
                        colors: [
                            Color.blue.opacity(0.15),
                            Color.purple.opacity(0.10),
                            Color.pink.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .opacity(isAnimating ? 0.7 : 0.0).padding(-26)
            )
            .opacity(textViewOpacity)
            .scaleEffect(isAnimating ? 1.03 : 1.0)
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 0, trailing: 12))
            .overlay(alignment: .bottomTrailing) {
                if showUndoButton {
                    undoButton
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
    }

    private var undoButton: some View {
        Button(action: undoExcerptChange) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .offset(y: -1)
                Text(SharedStrings.Button.undo)
            }
            .font(.footnote.weight(.medium))
        }
        .buttonStyle(.bordered)
        .tint(Color.primary)
        .padding(12)
    }

    private func onGeneratedExcerptSelected(_ newText: String) {
        previousText = text

        // Hide the placeholder and update the text without animation
        text = newText
        textViewOpacity = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            withAnimation(.spring(duration: 0.4)) {
                isAnimating = true
                textViewOpacity = 1.0
                showUndoButton = true
            }

            hideUndoButtonTask = Task {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.25)) {
                    showUndoButton = false
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(duration: 0.33)) {
                    isAnimating = false
                }
            }
        }
    }

    private func undoExcerptChange() {
        hideUndoButtonTask?.cancel()
        withAnimation(.spring) {
            text = previousText
            showUndoButton = false
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

private extension String {
    var wordCount: Int {
        var count = 0
        enumerateSubstrings(in: startIndex..<endIndex, options: [.byWords, .localized]) { _, _, _, _ in
            count += 1
        }
        return count
    }
}

private enum Strings {
    static let characterCount = NSLocalizedString(
        "postSettings.excerpt.characterCount",
        value: "%1$d characters",
        comment: "Character count for excerpt. %1$d is the number of characters."
    )

    static let wordCount = NSLocalizedString(
        "postSettings.excerpt.wordCount",
        value: "%1$d words",
        comment: "Word count for excerpt. %1$d is the number of words."
    )
}

#if DEBUG

@available(iOS 26, *)
#Preview {
    @Previewable @State var text = ""

    NavigationView {
        PostSettingsExcerptEditor(postContent: PostSettingsExcerptEditor.mockPostContent, text: $text)
    }
    .accentColor(AppColor.primary)
}

extension PostSettingsExcerptEditor {
    static let mockPostContent = """
        WordPress has revolutionized the way we think about content management and publishing. From its humble beginnings as a simple blogging platform in 2003, WordPress has grown to power over 40% of all websites on the internet today.

        What makes WordPress truly special is its flexibility and extensibility. With thousands of themes and plugins available, you can transform a basic WordPress installation into virtually any type of website – from personal blogs and portfolios to complex e-commerce stores and corporate websites.

        The WordPress mobile app brings this power directly to your fingertips. Whether you're commuting, traveling, or simply away from your desk, you can manage your entire WordPress site from your iPhone or iPad. Create and edit posts, moderate comments, upload photos, check your site's analytics, and even customize your theme – all from the convenience of your mobile device.

        One of the most compelling features of WordPress is its built-in SEO capabilities. The platform generates clean, semantic HTML that search engines love, and when combined with plugins like Yoast SEO or RankMath, you have everything you need to rank well in search results.

        The WordPress community is another major strength. With millions of developers, designers, and content creators contributing to the ecosystem, there's always someone ready to help solve problems or share knowledge. From WordCamps and meetups to online forums and documentation, the support network is truly remarkable.

        Looking ahead, WordPress continues to evolve with modern web standards. The introduction of the block editor (Gutenberg) has made content creation more visual and intuitive, while full-site editing capabilities are transforming how we think about WordPress themes and customization. Whether you're a beginner starting your first blog or an experienced developer building complex sites, WordPress provides the tools and flexibility you need to succeed online.
    """
}

#endif
