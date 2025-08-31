import SwiftUI

struct EditCardMenuContent: View {
    let cardViewModel: TrafficCardViewModel

    var body: some View {
        if cardViewModel.configurationDelegate != nil {
            Section {
                contents
            }
        }
    }

    @ViewBuilder
    private var contents: some View {
        Menu {
            ControlGroup {
                Button {
                    cardViewModel.configurationDelegate?.moveCard(cardViewModel, direction: .up)
                } label: {
                    Label(Strings.Buttons.moveUp, systemImage: "arrow.up")
                }

                Button {
                    cardViewModel.configurationDelegate?.moveCard(cardViewModel, direction: .top)
                } label: {
                    Label(Strings.Buttons.moveToTop, systemImage: "arrow.up.to.line")
                }
            }

            ControlGroup {
                Button {
                    cardViewModel.configurationDelegate?.moveCard(cardViewModel, direction: .down)
                } label: {
                    Label(Strings.Buttons.moveDown, systemImage: "arrow.down")
                }

                Button {
                    cardViewModel.configurationDelegate?.moveCard(cardViewModel, direction: .bottom)
                } label: {
                    Label(Strings.Buttons.moveToBottom, systemImage: "arrow.down.to.line")
                }
            }
        } label: {
            Label(Strings.Buttons.moveCard, systemImage: "arrow.up.arrow.down")
        }
        Button {
            cardViewModel.isEditing = true
        } label: {
            Label(Strings.Buttons.customize, systemImage: "widget.small")
        }
        Button(role: .destructive) {
            cardViewModel.configurationDelegate?.deleteCard(cardViewModel)
        } label: {
            Label(Strings.Buttons.deleteWidget, systemImage: "trash")
                .tint(Color.red)
        }
    }
}
