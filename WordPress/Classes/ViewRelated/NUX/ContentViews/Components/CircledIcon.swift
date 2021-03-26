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

    private let shadowRadius: CGFloat = 4
    private let shadowColor = Color.gray.opacity(0.4)

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
                .shadow(color: shadowColor, radius: shadowRadius)
                .frame(width: size, height: size)

            Image(uiImage: UIImage.gridicon(iconType, size: CGSize(width: size / 2, height: size / 2)))
                .foregroundColor(iconColor)
        }
        .fixedSize()
        .offset(x: xOffset, y: yOffset)
    }
}
