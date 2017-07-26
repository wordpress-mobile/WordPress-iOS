import UIKit

class EpilogueSegue: UIStoryboardSegue {
    override func perform() {
        guard let navController = source.navigationController else {
            return
        }
        navController.setViewControllers([destination], animated: true)
    }
}
