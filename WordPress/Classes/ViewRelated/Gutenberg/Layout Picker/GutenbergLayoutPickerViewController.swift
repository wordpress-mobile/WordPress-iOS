import UIKit
import Gridicons

class GutenbergLayoutPickerViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var createBlankPageBtn: UIButton!
    @IBOutlet weak var closeButton: UIButton!

    override func viewDidLoad() {

        let seperator: UIColor
        if #available(iOS 13.0, *) {
            seperator =  UIColor.separator
        } else {
            seperator =  UIColor(red: 0.235, green: 0.235, blue: 0.263, alpha: 0.29)
        }

        headerView.layer.borderColor = seperator.cgColor
        headerView.layer.borderWidth = 0.5

        footerView.layer.borderColor = seperator.cgColor
        footerView.layer.borderWidth = 0.5

        createBlankPageBtn.layer.borderColor = seperator.cgColor
        createBlankPageBtn.layer.borderWidth = 0.5
        createBlankPageBtn.layer.cornerRadius = 8

        var tableFooterFrame = footerView.frame
        tableFooterFrame.origin.x = 0
        tableFooterFrame.origin.y = 0
        tableFooterFrame.size.height -= UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 44
        let tableFooterView = UIView(frame: tableFooterFrame)
        tableView.tableFooterView = tableFooterView

        closeButton.setImage(UIImage.gridicon(.crossSmall), for: .normal)

        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = false
        super.viewDidDisappear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationController?.isNavigationBarHidden = false
        super.prepare(for: segue, sender: sender)
    }

    @IBAction func closeModal(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension GutenbergLayoutPickerViewController: UITableViewDelegate {

}

extension GutenbergLayoutPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 318
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        return cell
    }
}
