import SwiftUI

struct EditCardMenuContent: View {
    let viewModel: StatsViewModel?
    let cardViewModel: TrafficCardViewModel
    
    var body: some View {
        if let viewModel {
            Section {
                Button(role: .destructive) {
                    viewModel.deleteCard(cardViewModel)
                } label: {
                    Label(Strings.Buttons.deleteWidget, systemImage: "trash")
                        .tint(Color.red)
                }
            }
        }
    }
}
