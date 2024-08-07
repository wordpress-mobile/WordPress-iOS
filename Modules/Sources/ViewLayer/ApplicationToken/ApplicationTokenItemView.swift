import SwiftUI
import DesignSystem

public struct ApplicationTokenItemView: View {

    @ObservedObject
    var viewModel: ViewModel

    private let token: ApplicationTokenItem

    public init(token: ApplicationTokenItem) {
        self.token = token
        self.viewModel = ViewModel(deviceName: token.name)
    }

    public var body: some View {
        ZStack {
            Form {
                DSEditableListDetailItemView(title: "Device Name", value: $viewModel.deviceName)

                DSListDetailItem(title: "Device UUID", value: token.uuid.uuidString)

                Section("Security") {
                    DSListDetailItem(title: "Creation Date", value: token.createdAt.formatted())

                    if let lastUsed = token.lastUsed {
                        DSListDetailItem(title: "Last Used", value: lastUsed.formatted())
                    }

                    if let lastIpAddress = token.lastIpAddress {
                        DSListDetailItem(title: "Last IP Address", value: lastIpAddress)
                    }
                }

                Section {
                    Button("Delete Application Token", role: .destructive) {
                        viewModel.promptForDeleteConfirmation()
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This is the application token. If you remove it, you'll need to login again to access your site.")
                }
            }
            .navigationTitle(token.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Save") {
                    viewModel.saveChanges()
                }.disabled(!viewModel.canSaveChanges)
            }
            .blur(radius: viewModel.isSavingChanges ? 0.8 : 0)
            .alert("Are you certain you want to delete this application token?", isPresented: $viewModel.isConfirmingDeletion) {
                Button("Delete Forever", role: .destructive) {
                    debugPrint("Deleting forever")
                }

                Button("Cancel", role: .cancel) {
                    debugPrint("never mind")
                }
            }

            if viewModel.isSavingChanges {
                ProgressView {
                    Text("Saving Application Password").style(.bodyLarge(.emphasized))
                }
                .padding()
                .progressViewStyle(.circular)
//                .controlSize(.extraLarge)
                .foregroundStyle(.primary)
                .background(in: .rect(cornerRadius: .DS.Radius.medium))
//                .backgroundStyle(.regularMaterial)
            }
        }

    }
}

#Preview {
    NavigationView {
        ApplicationTokenItemView(token: .aliceToken)
    }
}

#Preview {
    NavigationView {
        ApplicationTokenItemView(token: .bobToken)
    }
}
