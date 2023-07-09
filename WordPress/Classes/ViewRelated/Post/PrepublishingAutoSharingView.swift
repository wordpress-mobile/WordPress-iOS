import SwiftUI

struct PrepublishingAutoSharingView: View {

    var body: some View {
        HStack {
            textStack
            Spacer()
            iconTrain
        }
    }

    var textStack: some View {
        VStack {
            Text("Sharing to @sporadicthoughts")
                .font(.body)
                .foregroundColor(Color(.label))
            Text("27/30 social shares remaining")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    var iconTrain: some View {
        HStack {
            if let uiImage = UIImage(named: "icon-tumblr") {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 32.0, height: 32.0)
                    .background(Color(UIColor.listForeground))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(UIColor.listForeground), lineWidth: 2.0))
            }
        }
    }

}
