import ContactUs
import SwiftUI

struct ContentView: View {

    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            if let questions = viewModel.questions {
                QuestionList(questions: questions)
            } else {
                Text("Loading...")
            }
        }
    }
}

struct QuestionList: View {

    let questions: [Question]

    @State private var alertPresented = false

    var body: some View {
        List(questions) { item in
            switch item.next {
            case .page(let _questions):
                NavigationLink(destination: QuestionList(questions: _questions)) {
                    Text(item.message)
                }
            case .url(let url):
                Button {
                    self.alertPresented.toggle()
                } label: {
                    Text(item.message)
                }
                .alert(isPresented: $alertPresented, content: {
                    Alert(
                        title: Text("TODO"),
                        message: Text("Load URL for \(url)"),
                        dismissButton: .default(Text("Dismiss"))
                    )
                })

            }
        }
    }
}

import Combine

class ViewModel: ObservableObject {

    let provider = ContactUsProvider()

    @Published var questions: [Question]? = .none

    private var cancellables = Set<AnyCancellable>()

    init() {
        provider
            .loadDecisionTree()
            .sink(
                receiveCompletion: { completion in
                    guard case .failure = completion else { return }
                    // TODO: Implement better error handling
                    self.questions = .none
                },
                receiveValue: { questions in
                    self.questions = questions
                }
            )
            .store(in: &cancellables)
    }
}

extension Question: Identifiable {

    public var id: String { message }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
