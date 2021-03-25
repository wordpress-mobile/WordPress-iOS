import Gridicons
import SwiftUI

/// view that renders a gridIcon in a circle of the given color
struct CircledIcon: View {

    private let size: CGFloat
    private let xOffset: CGFloat
    private let yOffset: CGFloat

    private let iconType: GridiconType

    private let backgroundColor: Color
    private let iconColor: Color

    init(size: CGFloat,
         xOffset: CGFloat,
         yOffset: CGFloat,
         iconType: GridiconType,
         backgroundColor: Color,
         iconColor: Color = .white) {

        self.size = size
        self.xOffset = xOffset
        self.yOffset = yOffset
        self.iconType = iconType
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
    }


    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(backgroundColor)
                .frame(width: size, height: size)

            Image(uiImage: UIImage.gridicon(iconType))
                .foregroundColor(iconColor)
        }
        .fixedSize()
        .offset(x: xOffset, y: yOffset)
    }
}
