import SwiftUI
import DesignSystem

class ReaderAnnouncementHeaderView: UITableViewHeaderFooterView, ReaderStreamHeader {

    weak var delegate: ReaderStreamHeaderDelegate?

    private let header: ReaderAnnouncementHeader

    init(doneButtonTapped: (() -> Void)? = nil) {
        self.header = ReaderAnnouncementHeader { [doneButtonTapped] in
            doneButtonTapped?()
        }

        super.init(reuseIdentifier: ReaderSiteHeaderView.classNameWithoutNamespaces())
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let view = UIView.embedSwiftUIView(self.header)
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        ])

        applyBackgroundColor(Constants.backgroundColor)
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

    fileprivate struct Constants {
        static let backgroundColor = UIColor.systemBackground
    }
}

// TODO: ReaderAnnouncementItem / Models

// MARK: - SwiftUI View

fileprivate struct ReaderAnnouncementHeader: View {

    // Determines what features should be listed (and its order).
    let entries: [Entry] = [.tagsStream, .readingPreferences]

    var onButtonTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: .DS.Padding.double) {
            Text(Strings.title)
                .font(.callout)
                .fontWeight(.semibold)

            ForEach(entries, id: \.title) { entry in
                announcementEntryView(entry)
            }

            DSButton(title: Strings.buttonTitle,
                     style: DSButtonStyle(emphasis: .primary, size: .large)) {
                onButtonTap?()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, .DS.Padding.medium)
        .background(Color(ReaderAnnouncementHeaderView.Constants.backgroundColor))
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
                "reader.announcement.entry.readingPreferences.title",
                value: "Reading Preferences",
                comment: "The title part of the feature announcement content for Reading Preferences."
            ),
            description: NSLocalizedString(
                "reader.announcement.entry.readingPreferences.description",
                value: "Choose colors and fonts that suit you. When you’re reading a post tap the AA icon at the top of the screen.",
                comment: "The description part of the feature announcement content for Reading Preferences."
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
                .accessibilityHidden(true)

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

// MARK: - Reader Announcement Coordinator

class ReaderAnnouncementCoordinator {

    let repository: UserPersistentRepository = UserPersistentStoreFactory.instance()

    var canShowAnnouncement: Bool {
        return !isDismissed && RemoteFeatureFlag.readerAnnouncementCard.enabled()
    }

    var isDismissed: Bool {
        get {
            repository.bool(forKey: Constants.key)
        }
        set {
            repository.set(newValue, forKey: Constants.key)
        }
    }

    private struct Constants {
        static let key = "readerAnnouncementCardDismissedKey"
    }
}
