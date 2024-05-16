import SwiftUI
import DesignSystem

class ReaderTagCardEmptyCell: UICollectionViewCell, Reusable {

    var tagTitle: String {
        get {
            swiftUIView.tagTitle
        }
        set {
            swiftUIView.tagTitle = newValue
        }
    }

    var retryHandler: (() -> Void)? = nil

    private lazy var swiftUIView: ReaderTagCardEmptyCellView = {
        ReaderTagCardEmptyCellView(buttonTapped: { [weak self] in
            self?.retryHandler?()
        })
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        let viewToEmbed = UIView.embedSwiftUIView(swiftUIView)
        contentView.addSubview(viewToEmbed)
        contentView.pinSubviewToAllEdges(viewToEmbed)
    }

    override func prepareForReuse() {
        tagTitle = String()
        retryHandler = nil
        super.prepareForReuse()
    }

    func configure(tagTitle: String, retryHandler: (() -> Void)?) {
        self.tagTitle = tagTitle
        self.retryHandler = retryHandler
    }
}

// MARK: - SwiftUI

private struct ReaderTagCardEmptyCellView: View {

    var tagTitle = String()
    var buttonTapped: (() -> Void)? = nil

    @ScaledMetric(relativeTo: Font.TextStyle.callout)
    private var iconLength = 32.0

    var body: some View {
        VStack(spacing: .DS.Padding.double) {
            Image(systemName: "wifi.slash")
                .resizable()
                .frame(width: iconLength, height: iconLength)
                .foregroundStyle(Color.DS.Foreground.secondary)

            // added to double the padding between the Image and the VStack.
            Spacer().frame(height: .hairlineBorderWidth)

            VStack(spacing: .DS.Padding.single) {
                Text(Strings.title)
                    .font(.callout)
                    .fontWeight(.semibold)

                Text(Strings.body)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                buttonTapped?()
            } label: {
                Text(Strings.buttonTitle)
                    .font(.callout)
                    .padding(.vertical, .DS.Padding.half)
                    .padding(.horizontal, .DS.Padding.single)
            }
        }
        .padding(.DS.Padding.single)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private struct Strings {
        static let title = NSLocalizedString(
            "reader.tagStream.cards.emptyView.error.title",
            value: "Posts failed to load",
            comment: """
            The title of an empty state component for one of the tags in the tag stream.
            This empty state component is displayed only when the app fails to load posts under this tag.
            """
        )

        static let body = NSLocalizedString(
            "reader.tagStream.cards.emptyView.error.body",
            value: "We couldn't load posts from this tag right now",
            comment: """
            The body text of an empty state component for one of the tags in the tag stream.
            This empty state component is displayed only when the app fails to load posts under this tag.
            """
        )

        static let buttonTitle = NSLocalizedString(
            "reader.tagStream.cards.emptyView.button",
            value: "Retry",
            comment: """
            Verb. The button title of an empty state component for one of the tags in the tag stream.
            This empty state component is displayed only when the app fails to load posts under this tag.
            When tapped, the app will try to reload posts under this tag.
            """
        )
    }
}
