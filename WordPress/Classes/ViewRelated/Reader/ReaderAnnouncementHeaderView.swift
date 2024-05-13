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

    var body: some View {
        VStack(alignment: .leading, spacing: .DS.Padding.double) {
            Text(Strings.title)
                .font(.callout)
                .fontWeight(.semibold)

            // TODO: Display announcement items, Localization

            HStack(spacing: .DS.Padding.double) {
                Image("reader-menu-tags", bundle: nil)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .foregroundColor(Color(.systemBackground))
                    .background(.primary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text("Tags Stream")
                        .font(.callout)
                        .fontWeight(.semibold)
                    Text("Tap the dropdown at the top and select Tags to access streams from your followed tags.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: .DS.Padding.double) {
                Image("reader-reading-preferences", bundle: nil)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .foregroundColor(Color(.systemBackground))
                    .background(.primary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text("Reading Preferences")
                        .font(.callout)
                        .fontWeight(.semibold)
                    Text("Choose colors and fonts that suit you. When you’re reading a post tap the AA icon at the top of the screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
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

    // TODO: Localization
    private struct Strings {
        static let title = "New in Reader"
        static let buttonTitle = "Done"
    }
}
