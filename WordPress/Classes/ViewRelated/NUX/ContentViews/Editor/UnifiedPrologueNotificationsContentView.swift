import SwiftUI

/// Prologue notifications page contents
struct UnifiedPrologueNotificationsContentView: View {
    var body: some View {
        GeometryReader { content in
            let spacingUnit = content.size.height * 0.06
            let notificationIconSize = content.size.height * 0.2
            let smallIconSize = content.size.height * 0.175
            let largerIconSize = content.size.height * 0.2
            let fontSize = content.size.height * 0.055
            let notificationFont = Font.system(size: fontSize,
                                               weight: .regular,
                                               design: .default)

            VStack {
                Spacer()
                RoundRectangleView {
                    HStack {
                        NotificationIcon(image: Appearance.topImage, size: notificationIconSize)
                        Text(string: Appearance.topElementTitle)
                            .font(notificationFont)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(.none)
                        Spacer()
                    }
                    .padding(spacingUnit / 2)

                    HStack {
                        CircledIcon(size: smallIconSize,
                                    xOffset: -smallIconSize * 0.7,
                                    yOffset: smallIconSize  * 0.7,
                                    iconType: .reply,
                                    backgroundColor: Color(UIColor.muriel(name: .celadon, .shade30)))

                        Spacer()

                        CircledIcon(size: smallIconSize,
                                    xOffset: smallIconSize * 0.25,
                                    yOffset: -smallIconSize  * 0.7,
                                    iconType: .star,
                                    backgroundColor: Color(UIColor.muriel(name: .yellow, .shade20)))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    HStack {
                        NotificationIcon(image: Appearance.middleImage, size: notificationIconSize)
                        Text(string: Appearance.middleElementTitle)
                            .font(notificationFont)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(.none)
                        Spacer()
                    }
                    .padding(spacingUnit / 2)
                }
                .fixedSize(horizontal: false, vertical: true)
                .offset(x: spacingUnit)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    HStack {
                        NotificationIcon(image: Appearance.bottomImage, size: notificationIconSize)
                        Text(string: Appearance.bottomElementTitle)
                            .font(notificationFont)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(.none)
                        Spacer()
                    }
                    .padding(spacingUnit / 2)

                    HStack {
                        Spacer()

                        CircledIcon(size: largerIconSize,
                                    xOffset: largerIconSize * 0.6,
                                    yOffset: largerIconSize  * 0.3,
                                    iconType: .comment,
                                    backgroundColor: Color(UIColor.muriel(name: .blue, .shade50)))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
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

private extension UnifiedPrologueNotificationsContentView {
    enum Appearance {
        static let topImage = "page3Avatar1"
        static let middleImage = "page3Avatar2"
        static let bottomImage = "page3Avatar3"

        static let topElementTitle: String = NSLocalizedString("*Madison Ruiz* liked your post", comment: "Example Like notification displayed in the prologue carousel of the app. Username should be marked with * characters and will be displayed as bold text.")
        static let middleElementTitle: String = NSLocalizedString("You received *50 likes* on your site today", comment: "Example Likes notification displayed in the prologue carousel of the app. Number of likes should marked with * characters and will be displayed as bold text.")
        static let bottomElementTitle: String = NSLocalizedString("*Johann Brandt* responded to your post", comment: "Example Comment notification displayed in the prologue carousel of the app. Username should be marked with * characters and will be displayed as bold text.")
    }
}
