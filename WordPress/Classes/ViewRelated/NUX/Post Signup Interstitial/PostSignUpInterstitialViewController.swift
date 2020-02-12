import UIKit

extension NSNotification.Name {
    static let createSite = NSNotification.Name(rawValue: "PSICreateSite")
    static let addSelfHosted = NSNotification.Name(rawValue: "PSIAddSelfHosted")
}

class PostSignUpInterstitialViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .listBackground
    }

    @IBAction func createSite(_ sender: Any) {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .createSite, object: nil)
        }
    }

    @IBAction func addSelfHosted(_ sender: Any) {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .addSelfHosted, object: nil)
        }
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
