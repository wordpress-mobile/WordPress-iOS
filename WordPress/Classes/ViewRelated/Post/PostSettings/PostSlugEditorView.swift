import SwiftUI
import WordPressUI

@MainActor
struct PostSlugEditorView: View {
    @Binding var slug: String
    let post: AbstractPost

    @FocusState private var isFocused: Bool

    private var effectiveSlug: String {
        if !slug.isEmpty {
            return slug
        } else if let suggestedSlug = post.suggested_slug, !suggestedSlug.isEmpty {
            return suggestedSlug
        } else {
            return ""
        }
    }

    private var placeholderText: String {
        if let suggestedSlug = post.suggested_slug, !suggestedSlug.isEmpty {
            return suggestedSlug
        }
        return Strings.slugPlaceholder
    }

    var body: some View {
        Form {
            textFieldSection
            previewSection
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFocused = true
        }
    }

    // MARK: - TextField

    @ViewBuilder
    private var textFieldSection: some View {
        Section {
            HStack {
                TextField(placeholderText, text: $slug)
                    .focused($isFocused)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: slug) { _, newValue in
                        // Sanitize the slug by replacing spaces with dashes and removing other whitespace
                        let sanitized = sanitizeSlug(newValue)
                        if sanitized != newValue {
                            slug = sanitized
                        }
                    }

                if !slug.isEmpty {
                    Button(action: {
                        slug = ""
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.customizeDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Link(destination: URL(string: "https://wordpress.com/support/permalinks-and-slugs/")!) {
                    (Text(Strings.learnMore) + Text(" ") + Text(Image(systemName: "arrow.up.right.square")))
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private var previewSection: some View {
        if let permalinkURL = makePermalinkURL() {
            Section(Strings.permalinkSectionTitle) {
                Link(destination: permalinkURL) {
                    HStack {
                        Text(makeFormattedPermalinkString())
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                            .animation(.easeInOut(duration: 0.2), value: effectiveSlug)

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = permalinkURL.absoluteString
                    }) {
                        Text(SharedStrings.Button.copyLink)
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        } else if !post.hasRemote() && post.blog.dotComID != nil {
            Section(Strings.permalinkSectionTitle) {
                Text(Strings.permalinkDraftNotice)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private let permalinkSlugPlaceholder = "%postname%"

    private func makePermalinkURL() -> URL? {
        guard let templateURL = post.permalinkTemplateURL,
              !templateURL.isEmpty,
              templateURL.firstRange(of: permalinkSlugPlaceholder) != nil else {
            return nil
        }
        let permalinkString = templateURL.replacingOccurrences(of: permalinkSlugPlaceholder, with: effectiveSlug)
        return URL(string: permalinkString)
    }

    private func makeFormattedPermalinkString() -> AttributedString {
        guard let templateURL = post.permalinkTemplateURL,
              !templateURL.isEmpty else {
            return AttributedString(effectiveSlug)
        }

        var attributedString = AttributedString(templateURL)

        // Find the placeholder range and replace it with the slug
        if let range = attributedString.range(of: permalinkSlugPlaceholder) {
            // Replace the placeholder with the slug
            attributedString.replaceSubrange(range, with: AttributedString(effectiveSlug))

            // Calculate the new range for the inserted slug
            let slugStartIndex = range.lowerBound
            let slugEndIndex = attributedString.index(slugStartIndex, offsetByCharacters: effectiveSlug.count)
            let slugRange = slugStartIndex..<slugEndIndex

            // Make the slug part bold
            attributedString[slugRange].font = .body.bold()
        }

        return attributedString
    }

    // MARK: - Slug Sanitization

    private func sanitizeSlug(_ input: String) -> String {
        // Convert to lowercase and replace spaces with dashes
        let lowercased = input.lowercased()
            .replacingOccurrences(of: " ", with: "-")

        // Keep only lowercase letters (supporting all locales), numbers, and hyphens
        let allowedCharacters = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "-"))

        let filtered = lowercased.unicodeScalars.compactMap { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : nil
        }

        return String(filtered)
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "postSettings.slug.navigationTitle",
        value: "Slug",
        comment: "Label for the slug field. Should be the same as WP core."
    )

    static let slugPlaceholder = NSLocalizedString(
        "postSettings.slug.placeholder",
        value: "Enter slug",
        comment: "Placeholder for the slug field"
    )

    static let customizeDescription = NSLocalizedString(
        "postSettings.slug.customizeDescription",
        value: "Customize the last part of the Permalink.",
        comment: "Description text explaining what the slug editor does"
    )

    static let learnMore = NSLocalizedString(
        "postSettings.slug.learnMore",
        value: "Learn more",
        comment: "Button text to learn more about permalinks"
    )

    static let permalinkSectionTitle = NSLocalizedString(
        "postSettings.slug.permalinkSection",
        value: "Permalink",
        comment: "Section title for the permalink preview"
    )

    static let permalinkLabel = NSLocalizedString(
        "postSettings.slug.permalinkLabel",
        value: "Permalink",
        comment: "Label for the permalink preview"
    )

    static let permalinkDraftNotice = NSLocalizedString(
        "postSettings.slug.permalinkDraftNotice",
        value: "The suggested permalink will appear when the draft is saved on the server",
        comment: "Notice shown when the post doesn't have a remote and permalink template is missing"
    )
}
