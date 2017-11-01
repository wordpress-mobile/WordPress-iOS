import Foundation

struct PortfolioViewModel {
    let posts: [RemotePost]

    init(posts: [RemotePost]) {
        self.posts = posts
    }
}
