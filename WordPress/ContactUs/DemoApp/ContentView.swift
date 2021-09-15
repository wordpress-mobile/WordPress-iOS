import ContactUs
import SwiftUI

struct ContentView: View {

    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            if let decisionTree = viewModel.decisionTree {
                DecisionTreeView(tree: decisionTree)
            } else {
                Text("Loading...")
            }
        }
    }
}

import Combine

class ViewModel: ObservableObject {

    let provider = ContactUsProvider()

    @Published var decisionTree: DecisionTree? = .none

    private var cancellables = Set<AnyCancellable>()

    init() {
        provider
            .loadDecisionTree()
            .sink(
                receiveCompletion: { completion in
                    guard case .failure = completion else { return }
                    // TODO: Implement better error handling
                    self.decisionTree = .none
                },
                receiveValue: { questions in
                    self.decisionTree = questions
                }
            )
            .store(in: &cancellables)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
