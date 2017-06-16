import Foundation

protocol LoginViewController {
    func setupNavBarIcon()
}

extension LoginViewController where Self: NUXAbstractViewController {
    func setupNavBarIcon() {
        let image = UIImage(named: "social-wordpress")
        let imageView = UIImageView(image: image?.imageWithTintColor(UIColor.white))
        navigationItem.titleView = imageView
    }
}
