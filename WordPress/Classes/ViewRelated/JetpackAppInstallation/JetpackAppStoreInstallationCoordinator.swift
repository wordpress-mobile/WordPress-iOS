import StoreKit

final class JetpackAppStoreInstallationCoordinator: NSObject, SKStoreProductViewControllerDelegate {
    static let shared = JetpackAppStoreInstallationCoordinator()

    func showJetpackAppInstallation(on viewController: UIViewController) {
        let storeProductVC = SKStoreProductViewController()
        storeProductVC.delegate = self

        let appID = [SKStoreProductParameterITunesItemIdentifier: "1565481562"]

        storeProductVC.loadProduct(withParameters: appID) { (result, error) in
            if result {
                viewController.present(storeProductVC, animated: true, completion: {
                    print("The store view controller was presented.")
                })
            } else {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
