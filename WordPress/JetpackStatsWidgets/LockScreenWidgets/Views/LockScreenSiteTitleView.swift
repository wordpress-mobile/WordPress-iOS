import SwiftUI

struct LockScreenSiteTitleView: View {
    let title: String
    let alignment: Alignment

    init(title: String, alignment: Alignment = .leading) {
        self.title = title
        self.alignment = alignment
    }

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: alignment)
            .font(.system(size: 10))
            .lineLimit(1)
            .allowsTightening(true)
    }
}
