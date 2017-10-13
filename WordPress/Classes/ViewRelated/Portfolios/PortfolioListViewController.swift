import UIKit

class PortfolioListViewController: UIViewController {
    var blog: Blog!
    class func controllerWithBlog(_ blog: Blog) -> PortfolioListViewController {
        let controller = PortfolioListViewController()
        controller.blog = blog
        return controller
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
