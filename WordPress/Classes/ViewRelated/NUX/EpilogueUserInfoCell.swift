import UIKit

class EpilogueUserInfoCell: UITableViewCell {

    @IBOutlet var gravatarView: UIImageView?
    @IBOutlet var fullNameLabel: UILabel?
    @IBOutlet var usernameLabel: UILabel?

    func configure(userInfo: LoginEpilogueUserInfo, showEmail: Bool = false) {
        fullNameLabel?.text = userInfo.fullName

        if showEmail == true {
            usernameLabel?.text = userInfo.email
        } else {
            usernameLabel?.text = "@\(userInfo.username)"
        }

        if let gravatarUrl = userInfo.gravatarUrl,
            let url = URL(string: gravatarUrl) {
            gravatarView?.downloadImage(url, placeholderImage: nil)
        } else {
            gravatarView?.downloadGravatarWithEmail(userInfo.email, rating: .x)
        }
    }

}
