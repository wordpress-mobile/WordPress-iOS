import Foundation

class LoginViewController: NUXAbstractViewController {
    @IBOutlet var errorLabel: UILabel?

    /// Places the WordPress logo in the navbar
    ///
    func setupNavBarIcon() {
        let image = UIImage(named: "social-wordpress")
        let imageView = UIImageView(image: image?.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }

    /// Sets the text of the error label.
    ///
    func displayError(message: String) {
        errorLabel?.text = message
    }
}
