//
//  DetailViewController.swift
//  IPLocate
//
//  Created by Nick Perkins on 10/17/16.
//  Copyright © 2016 Nick Perkins. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController {
    
    @IBOutlet var detailMapView: MKMapView!
    @IBOutlet var countryFlagImageView: UIImageView!
    @IBOutlet var localInfoLabel: UILabel!
    @IBOutlet var coordinatesLabel: UILabel!
    @IBOutlet var countryNameLabel: UILabel!
    @IBOutlet var cityNameLabel: UILabel!
    @IBOutlet var regionNameLabel: UILabel!
    @IBOutlet var zipCodeLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var informationView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!
    
    var passedValue: String!
    var results: Array<IPAddress> = []
    let defaults = UserDefaults.standard
    var selectedIPAddress: IPAddress!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getData()
        
        for item in self.results {
            
            if item.theIPAddress == passedValue {
                selectedIPAddress = item
                break
            }
        }
        
        //Add Map Pin to detailMapView
        let latitude = CLLocationDegrees((selectedIPAddress?.latitude)!)
        let longitude = CLLocationDegrees((selectedIPAddress?.longitude)!)
        let coordinates = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        let newPin = MapPin(coordinate: coordinates, title: (selectedIPAddress?.theIPAddress)!, subtitle: "\(selectedIPAddress!.cityName), \(selectedIPAddress!.regionName)")
        self.detailMapView.addAnnotation(newPin)
        let region = MKCoordinateRegionMakeWithDistance(newPin.coordinate, 2000, 2000)
        self.detailMapView.setRegion(region, animated: false)
        
        // Add inforamtion to the view.
        let countryFlagFileName = "\(selectedIPAddress.countryCode)"
        let imageFilePath = Bundle.main.path(forResource: countryFlagFileName, ofType: "png", inDirectory: "countryFlags")!
        countryFlagImageView.image = UIImage(contentsOfFile: imageFilePath)
        detailMapView.bringSubview(toFront: countryFlagImageView)
        coordinatesLabel.text = "Coordinates: \(selectedIPAddress.latitude), \(selectedIPAddress.longitude)"
        countryNameLabel.text = "Country: \(selectedIPAddress.countryName)"
        cityNameLabel.text = "City: \(selectedIPAddress.cityName)"
        regionNameLabel.text = "Region: \(selectedIPAddress.regionName)"
        zipCodeLabel.text = "Zip Code: \(selectedIPAddress.zipCode)"
        detailMapView.isUserInteractionEnabled = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "\(passedValue!)"
    }
    
    override func viewDidLayoutSubviews() {
        // Layout bounds of Scroll View
        let scrollViewBounds = scrollView.bounds
        //let containerViewBounds = contentView.bounds
        
        var scrollViewInsets = UIEdgeInsets.zero
        scrollViewInsets.top = scrollViewBounds.size.height/2.0;
        scrollViewInsets.top -= contentView.bounds.size.height/2.0;
        
        scrollViewInsets.bottom = scrollViewBounds.size.height/2.0
        scrollViewInsets.bottom -= contentView.bounds.size.height/2.0;
        
        if(UIDeviceOrientationIsLandscape(UIDevice.current.orientation))
        {
            scrollViewInsets.bottom += 175
        }
        
        if(UIDeviceOrientationIsPortrait(UIDevice.current.orientation))
        {
            scrollViewInsets.bottom += 1
        }
        
        scrollView.contentInset = scrollViewInsets
        
        applyShadow(object: informationView)
        applyShadow(object: countryFlagImageView)
    }
    
    // MARK: MapView Delegate Methods
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if(pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = true
        }
        return pinView
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "backToTableSegue" {
            
        } else if segue.identifier == "backToMapSegue" {
            
        }else{
            print ("error with segue!")
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

    @IBAction func deleteRecordAndReturnToLastLocation(_ sender: AnyObject) {
        
        //Here an alert will be called. If the user decides to delete the record will be removed from self.results and the UserDefaults will be updated, the user will automatically go back to the last location.
        
        for record in self.results {
            if record.theIPAddress == "\(selectedIPAddress.theIPAddress)" {
                let recordToDelete = self.results.index(of: record)
                self.results.remove(at: recordToDelete!)
                updateUserDefaults()
                let data = ["ipaddress" : record]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RemovePinFromMap"), object: nil, userInfo: data)
                print("\(record.theIPAddress) record deleted!")
                break
            }
        }
        // Call for Table Data to be reloaded and for previous view controller to display
        let data = ["array" : self.results]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReloadTableData"), object: nil, userInfo: data)
        self.navigationController?.popViewController(animated: true);
        
        dismiss(animated: true, completion: nil)
    }
    
    func applyShadow(object: AnyObject) {
        let layer = object.layer!
        
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 5
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
}
