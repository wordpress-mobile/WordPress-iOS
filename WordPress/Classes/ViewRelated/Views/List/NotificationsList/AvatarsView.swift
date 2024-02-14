import SwiftUI
import DesignSystem
import WordPressUI

struct AvatarsView: View {
    private enum Constants {
        static let doubleAvatarHorizontalOffset: CGFloat = 18
    }

    enum Style {
        case single(URL)
        case double(URL, URL)
        case triple(URL, URL, URL)

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
                return Length.Padding.split/2
            }
        }

        var verticalOffset: CGFloat {
            switch self {
            case .single, .double:
                return 0
            case .triple:
                return Length.Padding.large/2
            }
        }
    }

    private let style: Style
    private let borderColor: Color

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

    private func avatar(url: URL) -> some View {
        let processedURL: URL
        if let gravatar = Gravatar(url) {
            let size = Int(ceil(style.diameter * UIScreen.main.scale))
            processedURL = gravatar.urlWithSize(size)
        } else {
            processedURL = url
        }

        return AsyncImage(url: processedURL) { image in
            image.resizable()
        } placeholder: {
            Image("gravatar")
                .resizable()
        }
        .frame(width: style.diameter, height: style.diameter)
        .clipShape(Circle())
    }

    private func doubleAvatarView(primaryURL: URL, secondaryURL: URL) -> some View {
        ZStack {
            HStack {
                avatar(url: secondaryURL)
                Spacer().frame(width: Constants.doubleAvatarHorizontalOffset)
            }
            HStack {
                Spacer().frame(width: Constants.doubleAvatarHorizontalOffset)
                avatar(url: primaryURL)
                    .avatarBorderOverlay()
            }
        }
    }

    private func tripleAvatarView(
        primaryURL: URL,
        secondaryURL: URL,
        tertiaryURL: URL
    ) -> some View {
        ZStack {
            HStack {
                avatar(url: tertiaryURL)
                Spacer().frame(width: Length.Padding.medium)
            }
            VStack {
                avatar(url: secondaryURL)
                    .avatarBorderOverlay()
                Spacer().frame(height: Length.Padding.large)
            }
            HStack {
                Spacer().frame(width: Length.Padding.medium)
                avatar(url: primaryURL)
                    .avatarBorderOverlay()
            }
        }
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
