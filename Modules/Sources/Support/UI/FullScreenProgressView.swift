import SwiftUI

struct FullScreenProgressView: View {

    private let string: String

    init(_ string: String) {
        self.string = string
    }

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProgressView(string)
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview {
    FullScreenProgressView("Loading Stuff")
}
