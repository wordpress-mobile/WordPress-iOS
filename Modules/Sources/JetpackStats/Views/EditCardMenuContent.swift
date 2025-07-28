import SwiftUI

struct EditCardMenuContent: View {
    let cardViewModel: TrafficCardViewModel
    
    var body: some View {
        Section {
            Button {
                cardViewModel.isEditing = true
            } label: {
                Label(Strings.Buttons.customize, systemImage: "slider.horizontal.3")
            }
            
            Button(role: .destructive) {
                cardViewModel.configurationDelegate?.deleteCard(cardViewModel)
            } label: {
                Label(Strings.Buttons.deleteWidget, systemImage: "trash")
                    .tint(Color.red)
            }
        }
    }
}
