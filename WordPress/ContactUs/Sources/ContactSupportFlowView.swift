import SwiftUI

/// The view that initiates the Contact Support with self-service decision tree flow
public struct ContactSupportFlowView: View {

    @ObservedObject private var viewModel = ViewModel()

    public init() {}

    public var body: some View {
        VStack {
            NavigationView {
                VStack {
                    if let decisionTree = viewModel.decisionTree {
                        DecisionTreeView(tree: decisionTree)
                    } else {
                        Text("Loading...")
                    }
                }
            }
            ContactSupportView()
        }
    }
}

import Combine

extension ContactSupportFlowView {

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
}
