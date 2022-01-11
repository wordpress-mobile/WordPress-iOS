import SwiftUI

struct QuickLinksView: View {
    var title: String

    var body: some View {
        Text(title)
            .padding()
    }
}

struct QuickLinksView_Previews: PreviewProvider {
    static var previews: some View {
        QuickLinksView(title: "Title")
    }
}
