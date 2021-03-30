import SwiftUI

/// Prologue stats page contents
struct UnifiedPrologueStatsContentView: View {

    var body: some View {

        GeometryReader { content in
            let globeIconSize = content.size.height * 0.22
            let alignImageLeftIconSize = content.size.height * 0.16
            let plusIconSize = content.size.height * 0.18

            VStack {

                RoundRectangleView {
                    Image("page4Map")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(EdgeInsets(top: content.size.height * 0.01,
                                            leading: content.size.height * 0.03,
                                            bottom: content.size.height * 0.01,
                                            trailing: content.size.height * 0.03))

                    HStack {
                        Spacer()
                        CircledIcon(size: globeIconSize,
                                    xOffset: globeIconSize * 0.75,
                                    yOffset: -globeIconSize * 0.125,
                                    iconType: .globe,
                                    backgroundColor: Color(UIColor.muriel(name: .celadon, .shade30)))

                    }

                }
                .frame(idealHeight: content.size.height * 0.57)
                .fixedSize(horizontal: false, vertical: true)
                .offset(x: -content.size.height * 0.03, y: 0)

                Spacer(minLength: content.size.height * 0.03)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    Image("barGraph")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.all, content.size.height * 0.05)
                    HStack {

                        CircledIcon(size: alignImageLeftIconSize,
                                    xOffset: -alignImageLeftIconSize * 0.75,
                                    yOffset: -alignImageLeftIconSize * 1.5,
                                    iconType: .status,
                                    backgroundColor: Color(UIColor.muriel(name: .purple, .shade50)))

                        Spacer()

                        CircledIcon(size: plusIconSize,
                                    xOffset: plusIconSize * 0.33,
                                    yOffset: plusIconSize * 0.875,
                                    iconType: .multipleUsers,
                                    backgroundColor: Color(UIColor.muriel(name: .blue, .shade50)))
                    }
                }
                .frame(idealHeight: content.size.height * 0.4)
                .fixedSize(horizontal: false, vertical: true)
                .offset(x: content.size.height * 0.03, y: 0)

            }
        }
    }
}
