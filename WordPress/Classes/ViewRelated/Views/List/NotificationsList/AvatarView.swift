import SwiftUI
import Gravatar
import AsyncImageKit
import DesignSystem
import WordPressUI

struct AvatarView<S: Shape>: View {
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
                return .DS.Padding.split / 2
            }
        }
    }

    private let avatarShape: S
    private let doubleAvatarHorizontalOffset: CGFloat = 18
    private let style: Style
    private let borderColor: Color
    private let placeholderImage: Image?
    private let diameter: CGFloat
    @ScaledMetric private var scale = 1

    init(
        avatarShape: S = Circle(),
        style: Style,
        diameter: CGFloat? = nil,
        borderColor: Color = Color.primary,
        placeholderImage: Image? = nil
    ) {
        self.avatarShape = avatarShape
        self.style = style
        self.diameter = diameter ?? style.diameter
        self.borderColor = borderColor
        self.placeholderImage = placeholderImage
    }

    var body: some View {
        switch style {
        case let .single(primaryURL):
            avatar(url: primaryURL)
                .overlay {
                    avatarShape
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                }
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
        let size = Int(ceil(diameter * UIScreen.main.scale))
        if let url, let gravatar = AvatarURL(url: url, options: .init(preferredSize: .pixels(size))) {
            processedURL = gravatar.url
        } else {
            processedURL = url
        }

        return CachedAsyncImage(url: processedURL) { image in
            image.resizable()
        } placeholder: {
            if let placeholderImage {
                placeholderImage
            } else {
                placeholderZStack
            }
        }
        .frame(width: diameter * scale, height: diameter * scale)
        .clipShape(avatarShape)
    }

    private func doubleAvatarView(primaryURL: URL?, secondaryURL: URL?) -> some View {
        ZStack {
            avatar(url: secondaryURL)
                .padding(.trailing, doubleAvatarHorizontalOffset * scale)
            avatar(url: primaryURL)
                .avatarBorderOverlay(shape: avatarShape)
                .padding(.leading, doubleAvatarHorizontalOffset * scale)
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
                .avatarBorderOverlay(shape: avatarShape)
                .offset(y: -.DS.Padding.split * scale)
                .padding(.bottom, .DS.Padding.split / 2 * scale)
            avatar(url: primaryURL)
                .avatarBorderOverlay(shape: avatarShape)
                .padding(.leading, .DS.Padding.medium * scale)
        }
        .padding(.top, .DS.Padding.split)
    }

    private var placeholderZStack: some View {
        ZStack {
            Color.secondary
            Image.DS.icon(named: .vector)
                .resizable()
                .frame(width: 18, height: 18)
                .tint(Color(UIAppColor.gray(.shade50)))
        }
    }
}

extension AvatarView.Style {
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
            self = AvatarView.Style.single(tempURLs[0])
        case 2:
            self = AvatarView.Style.double(tempURLs[0], tempURLs[1])
        default:
            self = AvatarView.Style.triple(tempURLs[0], tempURLs[1], tempURLs[2])
        }
    }
}

private extension View {
    func avatarBorderOverlay<S: Shape>(shape: S) -> some View {
        self.overlay(
            shape
                .stroke(Color(.systemBackground), lineWidth: 1)
        )
    }
}
