import UIKit

class ProjectTableViewCell: UITableViewCell {
    @IBOutlet fileprivate weak var projectImageView: UIImageView!
    @IBOutlet fileprivate weak var projectTitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white
    }

    func configure(title: String, imageURLString: String) {
        projectTitle.text = title
        guard let url = URL(string: imageURLString) else { return }
        let data = try? Data(contentsOf: url)

        if let imageData = data {
            projectImageView.image = UIImage(data: imageData)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
