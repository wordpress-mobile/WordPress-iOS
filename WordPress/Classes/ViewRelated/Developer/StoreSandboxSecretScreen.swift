import SwiftUI
import WebKit

struct StoreSandboxSecretScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var secret: String

    /// Both consumers of the `store_sandbox` cookie read `HTTPCookieStorage.shared`
    /// directly, so writing to any other storage would silently not apply the sandbox.
    private let cookieStorage: HTTPCookieStorage = .shared

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text(verbatim: "Enter the Store Sandbox Cookie Secret:")
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
                if self.presentationMode.wrappedValue.isPresented == false {
                    StoreSandboxCookie.update(secret: secret, in: cookieStorage)
                    // Web views keep their own copy of the cookie in the default data store.
                    let webCookieStore = WKWebsiteDataStore.default().httpCookieStore
                    StoreSandboxCookie.synchronize(from: cookieStorage, to: webCookieStore) {}
                }
            }
        }
    }

    init() {
        if let cookie = StoreSandboxCookie.cookie(in: cookieStorage) {
            _secret = State(initialValue: cookie.value)
        } else {
            _secret = State(initialValue: "")
        }
    }
}

struct StoreSandboxSecretScreen_Previews: PreviewProvider {
    static var previews: some View {
        StoreSandboxSecretScreen()
    }
}
