import SwiftUI

/// Prologue intro view
struct UnifiedPrologueIntroContentView: View {

    var body: some View {
        GeometryReader { content in
            HStack(spacing: content.size.width * 0.067) {

                VStack(alignment: .trailing, spacing: content.size.height * 0.03) {
                    PrologueIntroImage(imageName: "introWebsite1", idealHeight: content.size.height * 0.6)

                    ZStack(alignment: .bottomLeading) {
                        PrologueIntroImage(imageName: "introWebsite4", idealHeight: content.size.height * 0.38)
                        CircledIcon(size: content.size.width * 0.15,
                                    xOffset: -content.size.width * 0.125,
                                    yOffset: content.size.height * 0.04,
                                    iconType: .pages,
                                    backgroundColor: Color(UIColor.muriel(name: .celadon, .shade30)))
                    }
                }

                VStack {
                    ZStack(alignment: .bottomLeading) {
                        PrologueIntroImage(imageName: "introWebsite2", idealHeight: content.size.height * 0.5)
                        CircledIcon(size: content.size.width * 0.18,
                                    xOffset: -content.size.width * 0.115,
                                    yOffset: -content.size.height * 0.07,
                                    iconType: .customize,
                                    backgroundColor: Color(UIColor.muriel(name: .orange, .shade30)))
                    }
                    .offset(x: 0, y: -content.size.height * 0.04)

                    HStack(alignment: .top, spacing: content.size.width * 0.067) {
                        PrologueIntroImage(imageName: "introWebsite5", idealHeight: content.size.height * 0.28)

                        PrologueIntroImage(imageName: "introWebsite6", idealHeight: content.size.height * 0.28)
                            .offset(x: 0, y: content.size.height * 0.067)
                    }
                }

                VStack(alignment: .trailing) {
                    PrologueIntroImage(imageName: "introWebsite3", idealHeight: content.size.height * 0.6)

                    ZStack(alignment: .topTrailing) {
                        PrologueIntroImage(imageName: "introWebsite7", idealHeight: content.size.height * 0.43)
                        CircledIcon(size: content.size.width * 0.22,
                                    xOffset: content.size.width * 0.06,
                                    yOffset: -content.size.height * 0.19,
                                    iconType: .create,
                                    backgroundColor: Color(UIColor.muriel(name: .pink, .shade40)))
                    }
                    .offset(x: 0, y: content.size.height * 0.03)
                }
            }
        }
    }
}


struct PrologueIntroImage: View {

    let imageName: String
    let idealHeight: CGFloat
    private let shadowRadius: CGFloat = 4
    private let shadowColor = Color.gray.opacity(0.4)

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(idealHeight: idealHeight)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(color: shadowColor, radius: shadowRadius)
    }
}
