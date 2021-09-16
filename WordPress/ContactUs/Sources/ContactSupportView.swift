import SwiftUI

struct ContactSupportView: View {

    @EnvironmentObject var contactSupportPresenter: ExternalSupportConversationPresenter

    var body: some View {
        VStack(spacing: 8) {
            Text("Can't find what you're looking for?").italic()
            Button {
                self.contactSupportPresenter.startExternalSupportConversation()
            } label: {
                Text("Contact Support")
            }
        }
    }
}
