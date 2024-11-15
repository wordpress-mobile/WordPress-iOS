import SwiftUI

struct UserProfileImage: View {

    private let size: CGFloat

    private let url: URL?

    init(size: CGFloat, url: URL?) {
        self.size = size
        self.url = url
    }

    var body: some View {
        if let url {
            AsyncImage(
                url: url,
                content: { image in
                    image.resizable()
                        .frame(width: size, height: size)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.circle)
                },
                placeholder: {
                    ProgressView().frame(width: size, height: size)
                }
            )
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: size, height: size)
                .clipShape(.circle)
        }
    }
}

#Preview("Default") {
    UserProfileImage(size: 64, url: nil)
}

#Preview {
    UserProfileImage(size: 64, url: URL(string: "https://gravatar.com/avatar/58fc51586c9a1f9895ac70e3ca60886e?size=256")!)
}
