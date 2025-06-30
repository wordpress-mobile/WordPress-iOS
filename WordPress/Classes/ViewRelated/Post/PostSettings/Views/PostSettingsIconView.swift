import SwiftUI
import WordPressUI

struct PostSettingsIconView: View {
    let imageName: String

    @ScaledMetric(relativeTo: .body) var width = 17

    init(_ imageName: String) {
        self.imageName = imageName
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 30, height: 30)

            ScaledImage(imageName, height: 19)
                .foregroundColor(.secondary)
        }
    }
}
