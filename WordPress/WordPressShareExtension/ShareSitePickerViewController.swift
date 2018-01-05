//
//  ShareSitePickerViewController.swift
//  WordPressShareExtension
//
//  Created by Will Kwon on 1/4/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import UIKit

class ShareSitePickerViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var modulesTableView: UITableView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var sitePickerTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        modulesTableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
