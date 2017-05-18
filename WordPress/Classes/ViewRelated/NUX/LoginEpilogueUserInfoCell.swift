import UIKit

class LoginEpilogueUserInfoCell: UITableViewCell {

    @IBOutlet var gravatarView: UIImageView?
    @IBOutlet var fullNameLabel: UILabel?
    @IBOutlet var usernameLabel: UILabel?

    func configure(userInfo: LoginEpilogueUserInfo) {
        usernameLabel?.text = "@\(userInfo.username)"
        fullNameLabel?.text = userInfo.fullName

        if let gravatarUrl = userInfo.gravatarUrl,
            let url = URL(string: gravatarUrl) {
            gravatarView?.downloadImage(url, placeholderImage: nil)
        } else {
            gravatarView?.downloadGravatarWithEmail(userInfo.email, rating: .x)
        }
    }
}
