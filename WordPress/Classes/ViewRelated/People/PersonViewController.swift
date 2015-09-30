import UIKit

public class PersonViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    public var blog: Blog!
    public var personID: Int!

    @IBOutlet var headerAvatarImageView: CircularImageView!
    @IBOutlet var headerDisplayNameLabel: UILabel!
    @IBOutlet var headerUsernameLabel: UILabel!
    @IBOutlet var roleCell: UITableViewCell!
    @IBOutlet var firstNameCell: UITableViewCell!
    @IBOutlet var lastnameCell: UITableViewCell!
    @IBOutlet var displayNameCell: UITableViewCell!

    private lazy var resultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@ AND userID = %@", self.blog.dotComID(), NSNumber(integer: self.personID))
        request.fetchLimit = 1

        // The results controller wants a sort descriptor or else it'll crash
        // There should be only one item, so we don't really care about sorting
        //
        // Maybe using a results controller to get updates on a single object
        // wasn't the smartest choice after all
        //
        // ¯\_(ツ)_/¯
        request.sortDescriptors = [NSSortDescriptor(key: "userID", ascending: true)]
        let context = ContextManager.sharedInstance().mainContext
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try resultsController.performFetch()
            updateUI()
        } catch {
            DDLogSwift.logError("Error fetching People: \(error)")
        }
    }

    func updateUI() {
        let managedPerson = resultsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! ManagedPerson
        let person = Person(managedPerson: managedPerson)
        let viewModel = PersonViewModel(person: person, blog: blog)
        bindViewModel(viewModel)
    }

    func bindViewModel(viewModel: PersonViewModel) {
        setAvatarURL(viewModel.avatarURL)
        headerDisplayNameLabel.text = viewModel.displayName
        headerUsernameLabel.text = viewModel.usernameText
        roleCell.detailTextLabel?.text = viewModel.roleText

        firstNameCell.hidden = viewModel.firstNameCellHidden
        lastnameCell.hidden = viewModel.lastNameCellHidden
        displayNameCell.hidden = viewModel.displayNameCellHidden

        firstNameCell.detailTextLabel?.text = viewModel.firstName
        lastnameCell.detailTextLabel?.text = viewModel.lastName
        displayNameCell.detailTextLabel?.text = viewModel.displayName
    }

    func setAvatarURL(avatarURL: NSURL?) {
        let placeholder = UIImage(named: "gravatar")!
        if let avatarURL = avatarURL {
            let size = headerAvatarImageView.frame.width * headerAvatarImageView.contentScaleFactor
            let scaledURL = avatarURL.patchGravatarUrlWithSize(size)

            headerAvatarImageView.setImageWithURL(scaledURL, placeholderImage: placeholder)
        } else {
            headerAvatarImageView.image = placeholder
        }
    }

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // TODO: if the model was deleted, dismiss the view
        updateUI()
    }
}