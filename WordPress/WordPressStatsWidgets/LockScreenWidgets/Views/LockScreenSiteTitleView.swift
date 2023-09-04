import SwiftUI
import WidgetKit

struct LockScreenSiteTitleView: View {
    var title: String

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(size: 11))
            .lineLimit(1)
    }
}
