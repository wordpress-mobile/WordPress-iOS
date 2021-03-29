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
            let fontSize = content.size.height * 0.05
            let notificationFont = Font.system(size: fontSize,
                                               weight: .regular,
                                               design: .default)
            let feedFont = Font.system(size: fontSize,
                                       weight: .regular,
                                       design: .default)

            VStack {
                Spacer(minLength: content.size.height * 0.1)

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
                .padding(.horizontal, spacingUnit)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading) {
                            HStack {
                                ForEach(["Art", "Cooking", "Football"], id: \.self) { item in
                                    Text(item)
                                        .font(notificationFont)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .padding(.horizontal, spacingUnit)
                                        .padding(.vertical, spacingUnit * 0.4)
                                        .background(Color(UIColor.muriel(name: .gray, .shade0)))
                                        .clipShape(Capsule())
                                }
                            }
                            HStack {
                                ForEach(["Gardening", "Music", "Politics"], id: \.self) { item in
                                    Text(item)
                                        .font(notificationFont)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .padding(.horizontal, spacingUnit)
                                        .padding(.vertical, spacingUnit * 0.4)
                                        .background(Color(UIColor.muriel(name: .gray, .shade0)))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(spacingUnit / 2)
                    }
                    .disabled(true)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    ScrollView(.horizontal) {
                        HStack {
                            VStack {
                                Image("page5Img1Coffee")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                Text("My Top Ten Cafes")
                                    .lineLimit(2)
                                    .font(notificationFont)
                            }
                            .frame(width: content.size.width * 0.3)
                            VStack {
                                Image("page5Img2Stadium")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                Text("The World's Best Fans")
                                    .lineLimit(2)
                                    .font(notificationFont)
                            }
                            .frame(width: content.size.width * 0.3)
                            VStack {
                                Image("page5Img3Museum")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                Text("Museums to See In London")
                                    .lineLimit(2)
                                    .font(notificationFont)
                            }
                            .frame(width: content.size.width * 0.3)
                        }
                        .padding(spacingUnit / 2)

                    }
                    .disabled(true)

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
                .padding(.horizontal, spacingUnit)

                // avoid bottom overlapping due to the icon offset
                Spacer(minLength: content.size.height * 0.18)
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
