import SwiftUI

struct SplashPrologueView: View {

    var body: some View {
        ZStack {
            Color(SplashPrologueStyleGuide.backgroundColor)
            HStack {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(minWidth: 0, maxWidth: .infinity)
                Image("splashBrushStroke")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.trailing, 20)
                    .foregroundColor(Color(SplashPrologueStyleGuide.BrushStroke.color))
            }

            VStack {
                Image("splashLogo")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding(10)
                Text(Self.caption)
                    .multilineTextAlignment(.center)
                    .font(SplashPrologueStyleGuide.Title.font)
                    .foregroundColor(Color(SplashPrologueStyleGuide.Title.textColor))
            }
        }
    }
}

private extension SplashPrologueView {
    static let caption = NSLocalizedString(
        "wordpress.prologue.splash.caption",
        value: """
        Write, edit, and publish
        from anywhere.
        """,
        comment: "Caption displayed during the login flow."
    )
}
