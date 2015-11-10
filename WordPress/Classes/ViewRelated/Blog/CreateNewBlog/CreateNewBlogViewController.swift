import UIKit

class CreateNewBlogViewController: UIViewController
{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: WPWalkthroughTextField!
    @IBOutlet weak var blogAddressTextField: WPWalkthroughTextField!
    @IBOutlet weak var createBlogButton: WPNUXMainButton!
    @IBOutlet weak var cancelButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleAttributes = WPNUXUtility.titleAttributesWithColor(UIColor.whiteColor()) as! [String: AnyObject]
        
        // Do any additional setup after loading the view.
        navigationItem.backBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        titleLabel.attributedText = NSAttributedString(string: "Create WordPress.com blog", attributes: titleAttributes)
        configureTextFields()
        configureCreateBlogButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureTextFields() {
        configureTitleTextField()
        configureBlogAddressTextField()
    }
    
    func configureTitleTextField() {
        let editImage = UIImage(named: "icon-email-field")
        let editImageView = UIImageView(image: editImage)
        editImageView.frame = CGRectMake(editImageView.frame.origin.x, editImageView.frame.origin.y, (editImage?.size.width)!, (editImage?.size.height)!)
        self.titleTextField.leftViewMode = .Always
        self.titleTextField.leftView = editImageView
        self.titleTextField.clipsToBounds = true
//        self.titleTextField.placeholder = "Title"
    }
    
    func configureBlogAddressTextField() {
        self.blogAddressTextField.leftViewMode = .Always
        let globeImageView = UIImageView(image: UIImage(named: "icon-menu-viewsite"))
        self.blogAddressTextField.leftView = globeImageView
//        self.blogAddressTextField.placeholder = "Blog address"
        let rightWordPressDotComTextView = UITextView(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        rightWordPressDotComTextView.text = ".wordpress.com"
        self.blogAddressTextField.rightView = rightWordPressDotComTextView
        self.blogAddressTextField.rightViewMode = .Always

    }
    
    func configureCreateBlogButton() {
        createBlogButton.setTitle("Create WordPress.com blog", forState: .Normal)
    }
    
    func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
