import SwiftUI

struct StoreSandboxSecretScreen: View {
    private static let storeSandboxSecretKey = "store_sandbox"

    @SwiftUI.Environment(\.presentationMode) var presentationMode
    @State private var secret: String
    private let cookieJar: CookieJar

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Enter the Store Sandbox Cookie Secret:")
                TextField("Secret", text: $secret)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .border(Color.black)
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        }
        .onDisappear() {
            // This seems to be necessary due to an iOS bug where
            // accessing presentationMode.wrappedValue crashes.
            DispatchQueue.main.async {
                if self.presentationMode.wrappedValue.isPresented == false,
                  let cookie = HTTPCookie(properties: [
                    .name: StoreSandboxSecretScreen.storeSandboxSecretKey,
                    .value: secret,
                    .domain: ".wordpress.com",
                    .path: "/"
                  ]) {
                    cookieJar.setCookies([cookie]) {}
                }
            }
        }
    }

    init(cookieJar: CookieJar) {
        var cookies: [HTTPCookie] = []

        self.cookieJar = cookieJar

        cookieJar.getCookies { jarCookies in
            cookies = jarCookies
        }

        if let cookie = cookies.first(where: { $0.name == StoreSandboxSecretScreen.storeSandboxSecretKey }) {
            _secret = State(initialValue: cookie.value)
        } else {
            _secret = State(initialValue: "")
        }
    }
}

struct StoreSandboxSecretScreen_Previews: PreviewProvider {
    static var previews: some View {
        StoreSandboxSecretScreen(cookieJar: HTTPCookieStorage.shared)
    }
}
