import SwiftUI

/// Prologue notifications page contents
struct UnifiedPrologueNotificationsContentView: View {
    var body: some View {
        GeometryReader { content in
            let spacingUnit = content.size.height * 0.06

            VStack {
                Spacer(minLength: content.size.height * 0.18)

                RoundRectangleView {
                    HStack {
                        NotificationIcon(image: Appearance.topImage, size: content.size.height * 0.2)
                        Text(Appearance.topElementTitle)
                            .font(Font.system(size: content.size.height * 0.05,
                                              weight: .regular,
                                              design: .default))
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
                        NotificationIcon(image: Appearance.middleImage, size: content.size.height * 0.2)
                        Text(Appearance.middleElementTitle)
                            .font(Font.system(size: content.size.height * 0.05,
                                              weight: .regular,
                                              design: .default))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(.none)
                        Spacer()
                    }
                    .padding(spacingUnit / 2)
                }
                .fixedSize(horizontal: false, vertical: true)
                .offset(x: content.size.width * 0.06)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    HStack {
                        NotificationIcon(image: Appearance.bottomImage, size: content.size.height * 0.2)
                        Text(Appearance.bottomElementTitle)
                            .font(Font.system(size: content.size.height * 0.05,
                                              weight: .regular,
                                              design: .default))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(.none)
                        Spacer()
                    }
                    .padding(spacingUnit / 2)
                }
                .fixedSize(horizontal: false, vertical: true)

                // avoid bottom overlapping due to the icon offset
                Spacer(minLength: content.size.height * 0.1)
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

        static let topElementTitle: LocalizedStringKey = "Madison Ruiz liked your post"
        static let middleElementTitle: LocalizedStringKey = "You received 50 likes on your site today"
        static let bottomElementTitle: LocalizedStringKey = "Johann Brandt responded to your post"
    }
}
