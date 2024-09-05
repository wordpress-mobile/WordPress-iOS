import SwiftUI

struct UserProfileImage: View {

    private let size: CGSize

    private let url: URL

    init(size: CGSize, email: String) {
        self.size = size
        self.url = URL(string: "https://gravatar.com/avatar/58fc51586c9a1f9895ac70e3ca60886e?size=256")!
    }

    init(size: CGSize, url: URL) {
        self.size = size
        self.url = url
    }

    var body: some View {
        AsyncImage(
            url: self.url,
            content: { image in
                image.resizable()
                    .frame(width: size.height, height: size.height)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 4.0))
            },
            placeholder: {
                ProgressView().frame(width: size.height, height: size.height)
            }
        )
    }
}

#Preview {
    UserProfileImage(size: CGSize(width: 64, height: 64), email: "test@example.com")
}
