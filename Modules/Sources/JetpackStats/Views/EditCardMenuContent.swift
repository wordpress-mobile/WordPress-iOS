import SwiftUI

struct EditCardMenuContent: View {
    let cardViewModel: TrafficCardViewModel
    
    @State private var cardIndex: Int?
    @State private var totalCards: Int = 0
    
    var body: some View {
        Section {
            Button {
                cardViewModel.isEditing = true
            } label: {
                Label(Strings.Buttons.customize, systemImage: "slider.horizontal.3")
            }
            
            Menu {
                ControlGroup {
                    Button {
                        cardViewModel.configurationDelegate?.moveCard(cardViewModel, direction: .up)
                    } label: {
                        Label(Strings.Buttons.moveUp, systemImage: "arrow.up")
                    }
                    .disabled(isFirstCard)

                    Button {
                        cardViewModel.configurationDelegate?.moveCard(cardViewModel, direction: .top)
                    } label: {
                        Label(Strings.Buttons.moveToTop, systemImage: "arrow.up.to.line")
                    }
                    .disabled(isFirstCard)
                }

                ControlGroup {
                    Button {
                        cardViewModel.configurationDelegate?.moveCard(cardViewModel, direction: .down)
                    } label: {
                        Label(Strings.Buttons.moveDown, systemImage: "arrow.down")
                    }
                    .disabled(isLastCard)

                    Button {
                        cardViewModel.configurationDelegate?.moveCard(cardViewModel, direction: .bottom)
                    } label: {
                        Label(Strings.Buttons.moveToBottom, systemImage: "arrow.down.to.line")
                    }
                    .disabled(isLastCard)
                }
            } label: {
                Label(Strings.Buttons.moveCard, systemImage: "arrow.up.arrow.down")
            }
            
            Button(role: .destructive) {
                cardViewModel.configurationDelegate?.deleteCard(cardViewModel)
            } label: {
                Label(Strings.Buttons.deleteWidget, systemImage: "trash")
                    .tint(Color.red)
            }
        }
        .onAppear {
            updateCardPosition()
        }
    }
    
    private var isFirstCard: Bool {
        cardIndex == 0
    }
    
    private var isLastCard: Bool {
        guard let index = cardIndex, totalCards > 0 else { return true }
        return index == totalCards - 1
    }
    
    private func updateCardPosition() {
        if let delegate = cardViewModel.configurationDelegate as? StatsViewModel {
            cardIndex = delegate.cards.firstIndex(where: { $0.id == cardViewModel.id })
            totalCards = delegate.cards.count
        }
    }
}
