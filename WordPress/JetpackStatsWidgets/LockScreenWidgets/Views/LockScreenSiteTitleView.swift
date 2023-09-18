import SwiftUI

struct LockScreenSiteTitleView: View {
    let title: String

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(size: 10))
            .lineLimit(1)
            .allowsTightening(true)
    }
}
