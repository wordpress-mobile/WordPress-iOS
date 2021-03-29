import SwiftUI

/// Prologue reader page contents
struct UnifiedPrologueReaderContentView: View {
    var body: some View {
        GeometryReader { content in
            let spacingUnit = content.size.height * 0.06
            let feedSize = content.size.height * 0.1

            let notificationIconSize = content.size.height * 0.2
            let smallIconSize = content.size.height * 0.15
            let largerIconSize = content.size.height * 0.2
            let fontSize = content.size.height * 0.055
            let notificationFont = Font.system(size: fontSize,
                                               weight: .regular,
                                               design: .default)
            let feedFont = Font.system(size: fontSize,
                                               weight: .regular,
                                               design: .default)

            VStack {
                Spacer(minLength: content.size.height * 0.18)

                RoundRectangleView {
                    HStack {
                        VStack {
                            Feed(image: Appearance.feedTopImage,
                                 imageSize: feedSize,
                                 title: Appearance.feedTopTitle,
                                 font: feedFont)
                            Feed(image: Appearance.feedMiddleImage,
                                 imageSize: feedSize,
                                 title: Appearance.feedMiddleTitle,
                                 font: feedFont)
                            Feed(image: Appearance.feedBottomImage,
                                 imageSize: feedSize,
                                 title: Appearance.feedBottomTitle,
                                 font: feedFont)
                        }
                    }
                    .padding(spacingUnit / 2)

//                    HStack {
//                        CircledIcon(size: smallIconSize,
//                                    xOffset: -smallIconSize * 0.75,
//                                    yOffset: smallIconSize  * 0.75,
//                                    iconType: .reply,
//                                    backgroundColor: Color(UIColor.muriel(name: .celadon, .shade30)))
//
//                        Spacer()
//
//                        CircledIcon(size: smallIconSize,
//                                    xOffset: smallIconSize * 0.25,
//                                    yOffset: -smallIconSize  * 0.75,
//                                    iconType: .star,
//                                    backgroundColor: Color(UIColor.muriel(name: .yellow, .shade20)))
//                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, spacingUnit / 2)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    HStack {
                        NotificationIcon(image: Appearance.feedMiddleImage, size: notificationIconSize)
                        Text(htmlString: Appearance.feedMiddleTitle)
                            .font(notificationFont)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(.none)
                        Spacer()
                    }
                    .padding(spacingUnit / 2)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    HStack {
                        NotificationIcon(image: Appearance.feedBottomImage, size: notificationIconSize)
                        Text(htmlString: Appearance.feedBottomTitle)
                            .font(notificationFont)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(.none)
                        Spacer()
                    }
                    .padding(spacingUnit / 2)

//                    HStack {
//                        Spacer()
//
//                        CircledIcon(size: largerIconSize,
//                                    xOffset: largerIconSize * 0.6,
//                                    yOffset: largerIconSize  * 0.3,
//                                    iconType: .comment,
//                                    backgroundColor: Color(UIColor.muriel(name: .blue, .shade50)))
//                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, spacingUnit / 2)

                // avoid bottom overlapping due to the icon offset
                Spacer(minLength: content.size.height * 0.1)
            }
        }
    }
}

private struct Feed: View {
    let image: String
    let imageSize: CGFloat
    let title: String
    let font: Font

    private let cornerRadius: CGFloat = 4.0

    var body: some View {
        HStack {
            Image(image)
                .resizable()
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(cornerRadius)
            Text(title)
                .font(font)
                .bold()
            Spacer()
        }
    }
}

private struct NotificationIcon: View {
    let image: String
    let size: CGFloat

    var body: some View {
        Image(image)
            .resizable()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

private extension UnifiedPrologueReaderContentView {
    enum Appearance {
        static let feedTopImage = "page5Avatar1"
        static let feedMiddleImage = "page5Avatar2"
        static let feedBottomImage = "page5Avatar3"

        static let feedTopTitle: String = "Pamela Nguyen"
        static let feedMiddleTitle: String = "Web News"
        static let feedBottomTitle: String = "Rock 'n Roll Weekly"
    }
}
