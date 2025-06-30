import SwiftUI
import WordPressUI

struct PostSettingsExcerptEditor: View {
    @Binding var text: String

    @State private var wordCount = 0

    @FocusState private var isFocused: Bool

    @Environment(\.dismiss) private var dismiss

    private let placeholder = PostSettingExcerptRow.localizedPlaceholderText

    var body: some View {
        Form {
            Section {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: 200)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(Color(.tertiaryLabel))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 0, trailing: 12))
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(SharedStrings.Button.done) {
                    dismiss()
                }
                .fontWeight(.medium)
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
                let wordCount = newValue.wordCount
                await MainActor.run {
                    self.wordCount = wordCount
                }
            }
        }
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
