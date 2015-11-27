import Foundation
import WordPressShared



public class SettingsCollectionEditorViewController : UITableViewController
{
    private var rows = [String]()
    
    public convenience init(collection: [String]?) {
        self.init(style: .Grouped)
        rows = collection?.sort() ?? [String]()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier)!
        WPStyleGuide.configureTableViewCell(cell)
        cell.textLabel?.text = rows[indexPath.row]
        return cell
    }
    
    
    private let reuseIdentifier = "WPTableViewCell"
}
