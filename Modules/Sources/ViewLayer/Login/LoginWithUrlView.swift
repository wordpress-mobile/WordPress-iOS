import SwiftUI
import AuthenticationServices

public struct LoginWithUrlView: View {

    open class ViewModel: ObservableObject {

        @Published
        public var urlField: String

        public init(urlField: String = "") {
            self.urlField = urlField
        }

        @MainActor
        open func startLogin() {

        }
    }

    @ObservedObject
    var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text("Enter the address of the WordPress site you'd like to connect.").padding(.vertical)

            TextField(text: $viewModel.urlField) {
                Text("example.com")
            }
            .padding(.vertical)
            .overlay(Divider(), alignment: .bottom)
            .tint(.green)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .onSubmit(viewModel.startLogin)

            Spacer()

            Button(action: viewModel.startLogin, label: {
                HStack(alignment: .center) {
                    Spacer()
                    Text("Continue")
                    Spacer()
                }.padding()
                    .background(
                        RoundedRectangle(
                            cornerRadius: .DS.Radius.small,
                            style: .continuous
                        )
                        .stroke(.primary, lineWidth: 2)
                    )
            })
            .tint(.primary)
        }.padding()
    }
}

struct LoginItemView: View {
    let stepName: String
    let success: Bool
    let loading: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if loading {
                Image(systemName: "circle.dashed").foregroundColor(.gray)
            } else {
                if success {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            Text(stepName)
        }
    }
}

#Preview {
    LoginWithUrlView(
        viewModel: LoginWithUrlView.ViewModel()
    )
}
