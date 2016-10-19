//
//  TableViewController.swift
//  IPLocate
//
//  Created by Nick Perkins on 10/17/16.
//  Copyright © 2016 Nick Perkins. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    @IBOutlet var editDoneButton: UIBarButtonItem!
    
    var results: Array<IPAddress> = []
    let defaults = UserDefaults.standard
    var valueToPass: String!
    var inEditMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Saved IP Addresses"
        
        //Remove extra cells being displayed
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        
        //Get data from UserDefaults
        getData()
        
        // NotificationCenter observers
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTableData(_:)), name: NSNotification.Name(rawValue: "ReloadTableData"), object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        let viewController = UINavigationBar.appearance()
        viewController.isTranslucent = false
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
        
        cell.detailTextLabel?.text = "\(data.regionName), \(data.countryName)"

        return cell
    }
    // Open selected record at IndexPath of object selected.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow!
        let cell = tableView.cellForRow(at: indexPath)! as UITableViewCell
        
        self.valueToPass = cell.textLabel?.text
        performSegue(withIdentifier: "detailVCSegue", sender: self)
        
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let mapPinToRemove = self.results[indexPath.row]
            self.results.remove(at: indexPath.row)
            updateUserDefaults()
            let data = ["ipaddress" : mapPinToRemove]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RemovePinFromMap"), object: nil, userInfo: data)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    
    // MARK: - Navigation

    // Unwind to close TableViewController that is presented modally
    @IBAction func closeModalViewController(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
        tableView.setEditing(false, animated: false)
    }
    
    // Send user to DetailViewController and pass data for displaying
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "detailVCSegue") {
            if let vc = segue.destination as? DetailViewController{
            print(valueToPass)
            vc.passedValue = valueToPass
            }
        }else{
            print("Another Segue was called that is not available.")
        }
    }
    
    // MARK: - Functions
    
    func getData() {
        //Is their data saved in UserDefaults? Yes: retrieve No: create
        if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
            self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
            self.results.sort(by: { $0.countryName < $1.countryName })
            print("I have data!")
        }else{
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: self.results), forKey: "PinsOnMap")
            if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
                self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
                self.results.sort(by: { $0.countryName < $1.countryName })
                print("I created data, now it is all mine!")
            }
        }
    }
    
    // Update data and add it to UserDefaults
    func updateUserDefaults() {
        self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: self.results), forKey: "PinsOnMap")
        if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
            self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
            self.results.sort(by: { $0.countryName < $1.countryName })
            print("Data saved in UserDefaults and results array updated.")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateNumberOfPinsToDisplay"), object: nil)
        }

    }
    
   // UIBarButton begins editing mode
    @IBAction func beginEditingMode(_ sender: AnyObject) {
        
        if inEditMode {
            tableView.setEditing(false, animated: true)
            editDoneButton.title = "Edit"
            inEditMode = false
        }else{
            tableView.setEditing(true, animated: true)
            editDoneButton.title = "Done"
            inEditMode = true
        }
    }
    
    func reloadTableData(_ notification: NSNotification) {
        
        let data = notification.userInfo?["array"] as! [IPAddress]
        self.results.removeAll()
        self.results = data
        updateUserDefaults()
        self.tableView.reloadData()
    }
    
}
