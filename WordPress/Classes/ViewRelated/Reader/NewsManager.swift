import Foundation
/// Abstracts the business logic supporting the New Card
protocol NewsManager {
    func dismiss()
    func readMore()
    func shouldPresentCard(contextId: Identifier) -> Bool
    func didPresentCard()
    func load(then completion: @escaping (Result<NewsItem>) -> Void)
}

protocol NewsManagerDelegate: class {
    func didDismissNews()
}

extension NSNotification.Name {
    static let NewsCardAvailable = NSNotification.Name(rawValue: "org.wordpress.newscardavailable")
    static let NewsCardNotAvailable = NSNotification.Name(rawValue: "org.wordpress.newscardnotavailable")
}

@objc extension NSNotification {
    public static let NewsCardAvailable = NSNotification.Name.NewsCardAvailable
    public static let NewsCardNotAvailable = NSNotification.Name.NewsCardNotAvailable
}
