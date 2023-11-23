import SwiftUI

struct LockScreenSiteTitleView: View {
    let title: String
    let alignment: Alignment
    let isIconShown: Bool

    init(title: String, alignment: Alignment = .leading, isIconShown: Bool = true) {
        self.title = title
        self.alignment = alignment
        self.isIconShown = isIconShown
    }

    var body: some View {
        HStack(spacing: 4) {
            if isIconShown {
                Image("icon-jetpack")
                    .resizable()
                    .frame(width: 11, height: 11)
            }
            Text(title)
                .frame(maxWidth: .infinity, alignment: alignment)
                .font(.system(size: 11))
                .lineLimit(1)
                .allowsTightening(true)
        }
    }
}
