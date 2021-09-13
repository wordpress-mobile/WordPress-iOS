import Combine

class ContactUsProvider {

    func loadDecisionTree() -> AnyPublisher<[Question], Error> {
        return Result.success(decisionTree).publisher.eraseToAnyPublisher()
    }
}

private let baseURL = "https://apps.wordpress.com/mobile-app-support"

let decisionTree: [Question] = [
    Question(
        message: "How do I connect a site?",
        next: .page(
            questions: [
                Question(
                    message: "Is your site on WordPress.com?",
                    next: .url(url: URL(string: "\(baseURL)/getting-started/#wordpresscom")!)
                )
            ]
        )
    )
]
