import SwiftUI
import Gravatar
import DesignSystem
import WordPressUI

struct AvatarsView: View {
    private enum Constants {
        static let doubleAvatarHorizontalOffset: CGFloat = 18
    }

    enum Style {
        case single(URL?)
        case double(URL?, URL?)
        case triple(URL?, URL?, URL?)

        var diameter: CGFloat {
            switch self {
            case .single:
                return 40
            case .double:
                return 32
            case .triple:
                return 28
            }
        }

        var leadingOffset: CGFloat {
            switch self {
            case .single:
                return 0
            case .double:
                return 5
            case .triple:
                return .DS.Padding.split/2
            }
        }
    }

    private let style: Style
    private let borderColor: Color
    @ScaledMetric private var scale = 1

    init(style: Style, borderColor: Color = .DS.Background.primary) {
        self.style = style
        self.borderColor = borderColor
    }

    var body: some View {
        switch style {
        case let .single(primaryURL):
            avatar(url: primaryURL)
        case let .double(primaryURL, secondaryURL):
            doubleAvatarView(
                primaryURL: primaryURL,
                secondaryURL: secondaryURL
            )
        case let .triple(primaryURL, secondaryURL, tertiaryURL):
            tripleAvatarView(
                primaryURL: primaryURL,
                secondaryURL: secondaryURL,
                tertiaryURL: tertiaryURL
            )
        }
    }

    private func avatar(url: URL?) -> some View {
        let processedURL: URL?
        let size = Int(ceil(style.diameter * UIScreen.main.scale))
        if let url, let gravatar = AvatarURL(url: url, options: .init(preferredSize: .pixels(size))) {
            processedURL = gravatar.url
        } else {
            processedURL = url
        }

        return CachedAsyncImage(url: processedURL) { image in
            image.resizable()
        } placeholder: {
            Image("gravatar")
                .resizable()
        }
        .frame(width: style.diameter * scale, height: style.diameter * scale)
        .clipShape(Circle())
    }

    private func doubleAvatarView(primaryURL: URL?, secondaryURL: URL?) -> some View {
        ZStack {
            avatar(url: secondaryURL)
                .padding(.trailing, Constants.doubleAvatarHorizontalOffset * scale)
            avatar(url: primaryURL)
                .avatarBorderOverlay()
                .padding(.leading, Constants.doubleAvatarHorizontalOffset * scale)
        }
    }

    private func tripleAvatarView(
        primaryURL: URL?,
        secondaryURL: URL?,
        tertiaryURL: URL?
    ) -> some View {
        ZStack(alignment: .center) {
            avatar(url: tertiaryURL)
                .padding(.trailing, .DS.Padding.medium * scale)
            avatar(url: secondaryURL)
                .avatarBorderOverlay()
                .offset(y: -.DS.Padding.split * scale)
                .padding(.bottom, .DS.Padding.split/2 * scale)
            avatar(url: primaryURL)
                .avatarBorderOverlay()
                .padding(.leading, .DS.Padding.medium * scale)
        }
        .padding(.top, .DS.Padding.split)
    }
}

extension AvatarsView.Style {
    init?(urls: [URL]) {
        var tempURLs: [URL]
        if urls.count > 3 {
            tempURLs = Array(urls.prefix(3))
        } else {
            tempURLs = urls
        }

        switch UInt(tempURLs.count) {
        case 0:
            return nil
        case 1:
            self = AvatarsView.Style.single(tempURLs[0])
        case 2:
            self = AvatarsView.Style.double(tempURLs[0], tempURLs[1])
        default:
            self = AvatarsView.Style.triple(tempURLs[0], tempURLs[1], tempURLs[2])
        }
    }
}

private extension View {
    func avatarBorderOverlay() -> some View {
        self.overlay(
            Circle()
                .stroke(Color.DS.Background.primary, lineWidth: 1)
        )
    }
}
