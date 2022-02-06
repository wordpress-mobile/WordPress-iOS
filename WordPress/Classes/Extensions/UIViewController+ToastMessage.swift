import UIKit
extension UIViewController {

    func showToast(message: String, font: UIFont) {

        let toastLabel = UILabel(frame: CGRect(x: 45, y: self.view.frame.size.height - 30, width: self.view.frame.width - 90, height: 30))
        toastLabel.backgroundColor = UIColor(red: 0.0/255.0, green: 160.0/255.0, blue: 210.0/255.0, alpha: 0.9)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 15
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
