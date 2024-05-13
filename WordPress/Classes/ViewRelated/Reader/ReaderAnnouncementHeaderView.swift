import SwiftUI
import DesignSystem

class ReaderAnnouncementHeaderView: UITableViewHeaderFooterView, ReaderStreamHeader {

    weak var delegate: ReaderStreamHeaderDelegate?

    init() {
        super.init(reuseIdentifier: ReaderSiteHeaderView.classNameWithoutNamespaces())
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let view = UIView.embedSwiftUIView(ReaderAnnouncementHeader())
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        ])

        applyBackgroundColor(.secondarySystemGroupedBackground)
        addBottomBorder(withColor: .separator)
    }

    private func applyBackgroundColor(_ color: UIColor) {
        let backgroundView = UIView(frame: bounds)
        backgroundView.backgroundColor = color
        self.backgroundView = backgroundView
    }

    // MARK: ReaderStreamHeader

    func enableLoggedInFeatures(_ enable: Bool) {
        // no-op
    }

    func configureHeader(_ topic: ReaderAbstractTopic) {
        // no-op; this header doesn't rely on the supplied topic.
    }
}

// TODO: ReaderAnnouncementItem / Models

// MARK: - SwiftUI View

fileprivate struct ReaderAnnouncementHeader: View {

    // Determines what features should be listed (and its order).
    let entries: [Entry] = [.tagsStream, .readingPreferences]

    var body: some View {
        VStack(alignment: .leading, spacing: .DS.Padding.double) {
            Text(Strings.title)
                .font(.callout)
                .fontWeight(.semibold)

            ForEach(entries, id: \.title) { entry in
                announcementEntryView(entry)
            }

            // DismissButton
            DSButton(title: Strings.buttonTitle,
                     style: DSButtonStyle(emphasis: .primary, size: .large)) {
                // TODO: Dismiss the header
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, .DS.Padding.medium)
        .background(Color(.listForeground))
    }

    // MARK: Constants

    private struct Strings {
        static let title = NSLocalizedString(
            "reader.announcement.title",
            value: "New in Reader",
            comment: "Title text for the announcement card component in the Reader."
        )
        static let buttonTitle = NSLocalizedString(
            "reader.announcement.button",
            value: "Done",
            comment: "Text for a button that dismisses the announcement card in the Reader."
        )
    }
}

// MARK: - Announcement Item

fileprivate extension ReaderAnnouncementHeader {

    struct Entry {
        static let tagsStream = Entry(
            imageName: "reader-menu-tags",
            title: NSLocalizedString(
                "reader.announcement.entry.tagsStream.title",
                value: "Tags Stream",
                comment: "The title part of the feature announcement content for Tags Stream."
            ),
            description: NSLocalizedString(
                "reader.announcement.entry.tagsStream.description",
                value: "Tap the dropdown at the top and select Tags to access streams from your followed tags.",
                comment: "The description part of the feature announcement content for Tags Stream."
            )
        )

        static let readingPreferences = Entry(
            imageName: "reader-reading-preferences",
            title: NSLocalizedString(
                "reader.announcement.entry.tagsStream.title",
                value: "Tags Stream",
                comment: "The title part of the feature announcement content for Tags Stream."
            ),
            description: NSLocalizedString(
                "reader.announcement.entry.tagsStream.description",
                value: "Tap the dropdown at the top and select Tags to access streams from your followed tags.",
                comment: "The description part of the feature announcement content for Tags Stream."
            )
        )

        let imageName: String
        let title: String
        let description: String
    }

    @ViewBuilder
    func announcementEntryView(_ entry: Entry) -> some View {
        HStack(spacing: .DS.Padding.double) {
            Image(entry.imageName, bundle: nil)
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .padding(12)
                .foregroundColor(Color(.systemBackground))
                .background(.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(entry.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
