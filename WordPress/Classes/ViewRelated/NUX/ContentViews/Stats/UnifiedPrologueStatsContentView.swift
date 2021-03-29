import SwiftUI

/// Prologue stats page contents
struct UnifiedPrologueStatsContentView: View {

    var body: some View {

        GeometryReader { content in

            VStack {
                Spacer(minLength: content.size.height * 0.18)

                RoundRectangleView {
                    Image("page4Map")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(EdgeInsets(top: content.size.height * 0.01,
                                            leading: content.size.height * 0.03,
                                            bottom: content.size.height * 0.01,
                                            trailing: content.size.height * 0.03))
                    let globeIconSize = content.size.height * 0.22
                    HStack {
                        Spacer()
                        CircledIcon(size: globeIconSize,
                                    xOffset: globeIconSize * 3 / 4,
                                    yOffset: -globeIconSize * 1 / 8,
                                    iconType: .globe,
                                    backgroundColor: Color(UIColor.muriel(name: .celadon, .shade30)))

                    }

                }
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
                        let alignImageLeftIconSize = content.size.height * 0.16
                        CircledIcon(size: alignImageLeftIconSize,
                                    xOffset: -alignImageLeftIconSize * 3 / 4,
                                    yOffset: -alignImageLeftIconSize * 3 / 2,
                                    iconType: .status,
                                    backgroundColor: Color(UIColor.muriel(name: .purple, .shade50)))

                        Spacer()

                        let plusIconSize = content.size.height * 0.18
                        CircledIcon(size: plusIconSize,
                                    xOffset: plusIconSize * 1 / 3,
                                    yOffset: plusIconSize * 7 / 8,
                                    iconType: .multipleUsers,
                                    backgroundColor: Color(UIColor.muriel(name: .blue, .shade50)))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .offset(x: content.size.height * 0.03, y: 0)

                // avoid bottom overlapping due to the icon offset
                Spacer(minLength: content.size.height * 0.1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
