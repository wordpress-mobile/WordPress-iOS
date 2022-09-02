import SwiftUI

struct SplashPrologueView: View {

    var body: some View {
        ZStack {
            Color(Self.Appearance.backgroundColor)
            HStack {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(minWidth: 0, maxWidth: .infinity)
                Image("splashBrushStroke")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.trailing, 20)
                    .foregroundColor(Color(Self.Appearance.brushStrokeColor))
            }

            VStack {
                Image("splashLogo")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding(10)
                Text(Self.Appearance.caption)
                    .multilineTextAlignment(.center)
                    .font(Self.Appearance.font)
                    .foregroundColor(Color(Self.Appearance.fontColor))
            }
        }
    }
}

private extension SplashPrologueView {
    enum Appearance {
        static let font = Font.custom("EBGaramond-Regular", size: 25)
        static let caption = NSLocalizedString(
            "wordpress.prologue.splash.caption",
            value: """
            Write, edit, and publish
            from anywhere.
            """,
            comment: "Caption displayed during the login flow."
        )

        static let fontColor = UIColor(light: .colorFromHex("101517"), dark: .white)
        static let backgroundColor = UIColor(light: .colorFromHex("F6F7F7"), dark: .colorFromHex("2C3338"))
        static let brushStrokeColor = UIColor(light: .colorFromHex("BBE0FA"), dark: .colorFromHex("101517")).withAlphaComponent(0.3)
    }
}
