import SwiftUI

/// Prologue reader page contents
struct UnifiedPrologueReaderContentView: View {
    var body: some View {
        GeometryReader { content in
            let spacingUnit = content.size.height * 0.06
            let feedSize = content.size.height * 0.1

            let smallIconSize = content.size.height * 0.175
            let largerIconSize = content.size.height * 0.25

            let fontSize = content.size.height * 0.05
            let smallFontSize = content.size.height * 0.045
            let smallFont = Font.system(size: smallFontSize, weight: .regular, design: .default)
            let feedFont = Font.system(size: fontSize,
                                       weight: .regular,
                                       design: .default)

            VStack {
                RoundRectangleView {
                    HStack {
                        VStack {
                            FeedRow(image: Appearance.feedTopImage,
                                 imageSize: feedSize,
                                 title: Strings.feedTopTitle,
                                 font: feedFont)
                            FeedRow(image: Appearance.feedMiddleImage,
                                 imageSize: feedSize,
                                 title: Strings.feedMiddleTitle,
                                 font: feedFont)
                            FeedRow(image: Appearance.feedBottomImage,
                                 imageSize: feedSize,
                                 title: Strings.feedBottomTitle,
                                 font: feedFont)
                        }
                    }
                    .padding(spacingUnit / 2)

                    HStack {
                        Spacer()

                        CircledIcon(size: largerIconSize,
                                    xOffset: largerIconSize * 0.7,
                                    yOffset: -largerIconSize * 0.05,
                                    iconType: .readerFollow,
                                    backgroundColor: Color(UIColor.muriel(name: .red, .shade40)))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, spacingUnit)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading) {
                            HStack {
                                ForEach([Strings.tagArt, Strings.tagCooking, Strings.tagFootball], id: \.self) { item in
                                    Text(item)
                                        .tagItemStyle(with: smallFont, horizontalPadding: spacingUnit, verticalPadding: spacingUnit * 0.25)
                                }
                            }
                            HStack {
                                ForEach([Strings.tagGardening, Strings.tagMusic, Strings.tagPolitics], id: \.self) { item in
                                    Text(item)
                                        .tagItemStyle(with: smallFont, horizontalPadding: spacingUnit, verticalPadding: spacingUnit * 0.25)
                                }
                            }
                        }
                        .padding(spacingUnit / 2)
                    }
                    .disabled(true)

                    HStack {
                        CircledIcon(size: smallIconSize,
                                    xOffset: -smallIconSize * 0.5,
                                    yOffset: -smallIconSize  * 0.7,
                                    iconType: .star,
                                    backgroundColor: Color(UIColor.muriel(name: .yellow, .shade20)))

                        Spacer()
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: spacingUnit / 2)
                    .fixedSize(horizontal: false, vertical: true)

                let postWidth = content.size.width * 0.3

                RoundRectangleView {
                    ScrollView(.horizontal) {
                        HStack {
                            PostView(image: Appearance.firstPostImage, title: Strings.firstPostTitle, size: postWidth, font: smallFont)
                            PostView(image: Appearance.secondPostImage, title: Strings.secondPostTitle, size: postWidth, font: smallFont)
                            PostView(image: Appearance.thirdPostImage, title: Strings.thirdPostTitle, size: postWidth, font: smallFont)
                        }
                        .padding(spacingUnit / 2)

                    }
                    .disabled(true)

                    HStack {
                        Spacer()

                        CircledIcon(size: smallIconSize,
                                    xOffset: smallIconSize * 0.75,
                                    yOffset: -smallIconSize * 0.85,
                                    iconType: .bookmarkOutline,
                                    backgroundColor: Color(UIColor.muriel(name: .purple, .shade50)))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, spacingUnit)
            }
        }
    }
}

private extension UnifiedPrologueReaderContentView {
    enum Appearance {
        static let feedTopImage = "page5Avatar1"
        static let feedMiddleImage = "page5Avatar2"
        static let feedBottomImage = "page5Avatar3"

        static let firstPostImage = "page5Img1Coffee"
        static let secondPostImage = "page5Img2Stadium"
        static let thirdPostImage = "page5Img3Museum"
    }

    enum Strings {
        static let feedTopTitle: String = "Pamela Nguyen"
        static let feedMiddleTitle: String = NSLocalizedString("Web News", comment: "Example Reader feed title")
        static let feedBottomTitle: String = NSLocalizedString("Rock 'n Roll Weekly", comment: "Example Reader feed title")

        static let tagArt: String = NSLocalizedString("Art", comment: "An example tag used in the login prologue screens.")
        static let tagCooking: String = NSLocalizedString("Cooking", comment: "An example tag used in the login prologue screens.")
        static let tagFootball: String = NSLocalizedString("Football", comment: "An example tag used in the login prologue screens.")
        static let tagGardening: String = NSLocalizedString("Gardening", comment: "An example tag used in the login prologue screens.")
        static let tagMusic: String = NSLocalizedString("Music", comment: "An example tag used in the login prologue screens.")
        static let tagPolitics: String = NSLocalizedString("Politics", comment: "An example tag used in the login prologue screens.")

        static let firstPostTitle: String = NSLocalizedString("My Top Ten Cafes", comment: "Example post title used in the login prologue screens.")
        static let secondPostTitle: String = NSLocalizedString("The World's Best Fans", comment: "Example post title used in the login prologue screens. This is a post about football fans.")
        static let thirdPostTitle: String = NSLocalizedString("Museums to See In London", comment: "Example post title used in the login prologue screens.")
    }
}

// MARK: - Views

/// A view showing an icon followed by a title for an example feed.
///
private struct FeedRow: View {
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

/// A view modifier that applies style to a text to make it look like a tag token.
///
private struct TagItem: ViewModifier {
    let font: Font
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Color(UIColor(light: UIColor.muriel(color: MurielColor(name: .gray, shade: .shade0)),
                                      dark: UIColor.muriel(color: MurielColor(name: .gray, shade: .shade70)))))
            .clipShape(Capsule())
    }
}

extension View {
    func tagItemStyle(with font: Font, horizontalPadding: CGFloat, verticalPadding: CGFloat) -> some View {
        self.modifier(TagItem(font: font, horizontalPadding: horizontalPadding, verticalPadding: verticalPadding))
    }
}

/// A view showing an image with title below for an example post.
///
private struct PostView: View {
    let image: String
    let title: String
    let size: CGFloat
    let font: Font

    var body: some View {
        VStack(alignment: .leading) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text(title)
                .lineLimit(2)
                .font(font)
        }
        .frame(width: size)
    }
}
