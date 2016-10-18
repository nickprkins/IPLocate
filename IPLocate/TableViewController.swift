//
//  TableViewController.swift
//  IPLocate
//
//  Created by Nick Perkins on 10/17/16.
//  Copyright © 2016 Nick Perkins. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    var results: Array<IPAddress> = []
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Remove extra cells being displayed
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //Get data from UserDefaults
        getData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.results.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let data = self.results[indexPath.row]
        
        // Configure the cell...
        
        // Get the file path for country flags
        let countryFlagFileName = "\(data.countryCode)"
        let imageFilePath = Bundle.main.path(forResource: countryFlagFileName, ofType: "png", inDirectory: "countryFlags")!
        
        cell.imageView?.image = UIImage(contentsOfFile: imageFilePath)
        cell.textLabel?.text = "\(data.theIPAddress)"
        
        cell.detailTextLabel?.text = "\(data.countryName)"

        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    @IBAction func closeModalViewController(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Functions
    
    func getData() {
        //Is their data saved in UserDefaults? Yes: retrieve No: create
        if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
            self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
            print("I have data!")
        }else{
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: self.results), forKey: "PinsOnMap")
            if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
                self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
                print("I created data, now it is all mine!")
            }
        }
    }

}
