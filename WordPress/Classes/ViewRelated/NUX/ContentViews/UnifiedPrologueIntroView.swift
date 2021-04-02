import SwiftUI

/// Prologue intro view
struct UnifiedPrologueIntroView: View {

    var body: some View {
        GeometryReader { content in
            HStack(spacing: content.size.width * 0.067) {

                VStack(alignment: .trailing, spacing: content.size.height * 0.03) {
                    Image("introWebsite1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(idealHeight: content.size.height * 0.6)
                        .fixedSize(horizontal: false, vertical: true)

                    Image("introWebsite4")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(idealHeight: content.size.height * 0.38)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack {
                    Image("introWebsite2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(idealHeight: content.size.height * 0.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(x: 0, y: -content.size.height * 0.04)

                    HStack(alignment: .top, spacing: content.size.width * 0.067) {
                        Image("introWebsite5")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(idealHeight: content.size.height * 0.28)
                            .fixedSize(horizontal: false, vertical: true)

                        Image("introWebsite6")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(idealHeight: content.size.height * 0.28)
                            .fixedSize(horizontal: false, vertical: true)
                            .offset(x: 0, y: content.size.height * 0.067)
                    }
                }

                VStack(alignment: .trailing) {
                    Image("introWebsite3")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(idealHeight: content.size.height * 0.6)
                        .fixedSize(horizontal: false, vertical: true)

                    Image("introWebsite7")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(idealHeight: content.size.height * 0.43)
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(x: 0, y: content.size.height * 0.03)
                }
            }
        }
    }
}
