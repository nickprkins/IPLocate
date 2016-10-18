//
//  MapViewController.swift
//  IPLocate
//
//  Created by Nick Perkins on 10/14/16.
//  Copyright © 2016 Nick Perkins. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var searchViewButton: UIButton!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var searchView: UIView!
    @IBOutlet var ipAddressRangeTextField: UITextField!
    @IBOutlet var ipAddressSingleTextField: UITextField!
    @IBOutlet var searchViewSegmentControl: UISegmentedControl!
    @IBOutlet var searchViewToLabel: UILabel!
    @IBOutlet var ipaddressCloneTextField: UILabel!
    @IBOutlet var currentLocationButton: UIButton!
    @IBOutlet var ipAddressesInfoView: UIView!
    @IBOutlet var showAllPinsButton: UIButton!
    @IBOutlet var listViewButton: UIButton!
    @IBOutlet var searchLayoutWidth: NSLayoutConstraint!
    @IBOutlet var searchLayoutHeight: NSLayoutConstraint!
    
    var client: APIManager!
    var results: Array<IPAddress>! = []
    var searchViewActive: Bool = false
    let defaults = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MapView setup
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        // API Setup
        self.client = APIManager()
        
        //Get data from UserDefaults add to Map
        getData()
        loadDataToMap()
        
        //Create Keyboard ToolBar
        createKeyboardToolbar()
        
        // NotificationCenter observers
        NotificationCenter.default.addObserver(self, selector: #selector(self.addAnnotationToMap(_:)), name: NSNotification.Name(rawValue: "HaveGoodIPAddress"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeSearchView(_:)), name: NSNotification.Name(rawValue: "CloseSearchView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.badIPAddressAlert(_:)), name: NSNotification.Name(rawValue: "HaveBadIPAddress"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Apply Shadows to Buttons and UIViews
        applyShadow(object: searchView)
        applyShadow(object: currentLocationButton)
        applyShadow(object: listViewButton)
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
            pinView!.animatesDrop = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        var accuracy: CLLocationAccuracy = (userLocation.location?.horizontalAccuracy)!
        // for lower battery consumption
        accuracy = 500.0
    }
    
    // MARK: Functions for View Controller
    func addAnnotationToMap(_ notification: NSNotification) {
        
        // Here call a function to reload the tableview data with the new results
        DispatchQueue.global(qos: .background).async {
            //This is run on the background queue
            self.results.append((notification.userInfo?["ipaddress"] as? IPAddress)!)
            
            //Update UserDefaults Stored Data
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: self.results), forKey: "PinsOnMap")
            if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
                self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
            }
            
            let newIPAddress = self.results.last
            let latitude = CLLocationDegrees((newIPAddress?.latitude)!)
            let longitude = CLLocationDegrees((newIPAddress?.longitude)!)
            let coordinates = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            let newPin = MapPin(coordinate: coordinates, title: (newIPAddress?.theIPAddress)!, subtitle: "\(newIPAddress!.cityName), \(newIPAddress!.regionName)")
            DispatchQueue.main.async {
               //This is run on the main queue, after the previous code in outer block
                self.mapView.addAnnotation(newPin)
                
                let region = MKCoordinateRegionMakeWithDistance(newPin.coordinate, 2000, 2000)
                
                self.mapView.setRegion(region, animated: true)
                
            }
        }
        
    }
    
    @IBAction func findCurrentLocation(_ sender: AnyObject) {
        
        let userLocation = mapView.userLocation
        
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 2000, 2000)
        
        self.mapView.setRegion(region, animated: true)
        
    }
    
    @IBAction func changeSearchView(_ sender: AnyObject) {
        
        if searchViewActive {
            searchLayoutWidth.constant = self.view.bounds.width * 0.9
            searchLayoutHeight.constant = 200
            self.searchViewSegmentControl.isHidden = false
            self.ipAddressSingleTextField.isHidden = false
            UIView.animate(withDuration: 0.7, animations: {
                self.searchView.layer.cornerRadius = 5
                self.view.layoutIfNeeded()
                
                
                
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400), execute: {
                // make form visible
                self.searchViewSegmentControl.alpha = 1
                self.ipAddressSingleTextField.alpha = 1
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.searchViewButton.setImage(UIImage(named: "closeIcon.png"), for: .normal)
                self.ipAddressSingleTextField.becomeFirstResponder()
            })
            
            searchViewActive = false
        }else{
            searchLayoutWidth.constant = 45
            searchLayoutHeight.constant = 45
            self.ipAddressSingleTextField.resignFirstResponder()
            UIView.animate(withDuration: 0.7, animations: {
                self.searchView.layer.cornerRadius = 0
                self.view.layoutIfNeeded()
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
                // make form invisible
                self.searchViewSegmentControl.alpha = 0
                self.ipAddressSingleTextField.alpha = 0
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.searchViewButton.setImage(UIImage(named: "logoIcon.png"), for: .normal)
                self.searchViewSegmentControl.isHidden = true
                self.ipAddressSingleTextField.isHidden = true
            })

            
            searchViewActive = true
        }
        
    }
    
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
    
    func loadDataToMap() {
        for pin in self.results {
            
            let latitude = CLLocationDegrees((pin.latitude))
            let longitude = CLLocationDegrees((pin.longitude))
            let coordinates = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            let newPin = MapPin(coordinate: coordinates, title: (pin.theIPAddress), subtitle: "\(pin.cityName), \(pin.countryName)")
            
            self.mapView.addAnnotation(newPin)
        }
    }
    
    func badIPAddressAlert(_ notification: NSNotification) {
        
        let data = notification.userInfo?["ipaddress"] as! IPAddress
        
        let alertController = UIAlertController(title: "\(data.theIPAddress) Unavailable", message: "This IP Address could not be found.", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // ...
        }
        alertController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // ...
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true) {
            // ...
        }
        
        
    }
    
    func applyShadow(object: AnyObject) {
        let layer = object.layer!
        
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 5
    }
    
    func createKeyboardToolbar() {
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 50))
        toolbar.barTintColor = UIColor(red: 244/255.0, green: 244/255.0, blue: 244/255.0, alpha: 1.0)
        toolbar.items = [
            UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelKeyboard)),
            UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
            UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.search, target: self, action: #selector(findIPOnMap))]
        toolbar.sizeToFit()
        ipAddressSingleTextField.inputAccessoryView = toolbar
        
    }
    
    func cancelKeyboard() {
        self.ipAddressSingleTextField.text = ""
        self.ipAddressSingleTextField.resignFirstResponder()
    }
    
    func findIPOnMap() {
        var singleTextField = self.ipAddressSingleTextField.text!
        self.ipAddressSingleTextField.text = ""
        self.ipAddressSingleTextField.resignFirstResponder()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CloseSearchView"), object: nil)
        self.client.findIPAddress(ipaddress: singleTextField)
    }
}

