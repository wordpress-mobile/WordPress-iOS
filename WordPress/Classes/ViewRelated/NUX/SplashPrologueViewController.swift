import Foundation

class SplashPrologueViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let contentView = UIView.embedSwiftUIView(SplashPrologueView())
        view.addSubview(contentView)
        view.pinSubviewToAllEdges(contentView)
    }
}
