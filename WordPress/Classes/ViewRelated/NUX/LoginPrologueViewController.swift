import UIKit
import Lottie

class LoginPrologueViewController: UIViewController {
    @IBOutlet var animationHolder: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let holder = animationHolder,
        let animation = LOTAnimationView(name: "notifications")
            else {
            return
        }
//        let animation = UIView()
        animation.translatesAutoresizingMaskIntoConstraints = false
//        animation.backgroundColor = UIColor.red
        animation.contentMode = .scaleAspectFit
        holder.addSubview(animation)
        
        // setup autolayout
        animation.leadingAnchor.constraint(equalTo: holder.leadingAnchor).isActive = true
        animation.trailingAnchor.constraint(equalTo: holder.trailingAnchor).isActive = true
        animation.topAnchor.constraint(equalTo: holder.topAnchor).isActive = true
        //animation.centerXAnchor.constraint(equalTo: holder.centerXAnchor).isActive = true
        animation.bottomAnchor.constraint(equalTo: holder.bottomAnchor).isActive = true
        
        animation.loopAnimation = true
        animation.play()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
