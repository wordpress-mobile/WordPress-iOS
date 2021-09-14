import Combine

class ContactUsProvider {

    func loadDecisionTree() -> AnyPublisher<[Question], Error> {
        return Result.success(decisionTree).publisher.eraseToAnyPublisher()
    }
}

private let baseURL = "https://apps.wordpress.com/mobile-app-support"

let decisionTree: [Question] = [
    Question(
        message: "How do I create a site?",
        next: .url(url: URL(string: "\(baseURL)/getting-started/#no-account")!)
    ),
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
    ),
    Question(
        message: "How do I create a new post?",
        next: .url(url: URL(string: "\(baseURL)/getting-started/#create-post")!)
    ),
    Question(
        message: "How do I create a new page?",
        next: .url(url: URL(string: "\(baseURL)/getting-started/#create-page")!)
    ),
]
