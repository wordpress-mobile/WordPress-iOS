//
//  ShareSitePickerViewController.swift
//  WordPressShareExtension
//
//  Created by Will Kwon on 1/4/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import UIKit

class ShareSitePickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var modulesTableView: UITableView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var sitePickerTableView: UITableView!
    var modules = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        modulesTableView.delegate = self
        modulesTableView.dataSource = self
        modulesTableView.backgroundColor = UIColor.blue
        modules = ["Featured Image", "Category", "Tags"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleTableCell", for: indexPath)
        
        cell.textLabel!.text = modules[indexPath.row]
        cell.detailTextLabel!.text = "yup"
        
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
