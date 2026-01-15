import SwiftUI

struct SystemMessageView: View {

    @Environment(\.sizeCategory)
    var sizeCategory

    let message: String

    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            HStack(alignment: .center) {
                if sizeCategory < .accessibilityMedium {
                    Image(systemName: "arrow.right.square")
                        .foregroundStyle(Color.secondary)
                    Spacer()
                }

                Text(message)
                    .foregroundStyle(Color.secondary)
                    .font(.footnote)
            }.padding()
            Divider()
        }
        .background(Color.gray.opacity(0.05))
    }
}

#Preview {
    SystemMessageView(message: "Conversation sent to human support")
}
