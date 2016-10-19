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
    @IBOutlet var listViewButton: UIButton!
    @IBOutlet var searchLayoutWidth: NSLayoutConstraint!
    @IBOutlet var searchLayoutHeight: NSLayoutConstraint!
    @IBOutlet var numberOfPins: UILabel!
    @IBOutlet var ipIconImageView: UIImageView!
    @IBOutlet var pinsActivityIndicator: UIActivityIndicatorView!
    
    
    var client: APIManager!
    var results: Array<IPAddress>! = []
    var searchViewActive: Bool = false
    let defaults = UserDefaults.standard
    var decimalCount = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MapView setup
        mapView.delegate = self
        mapView.showsUserLocation = true
        self.ipAddressesInfoView.isHidden = false
        UIView.animate(withDuration: 0.7, animations: {
            
            self.ipAddressesInfoView.alpha = 1
            
            
        })
        
        // API Setup
        self.client = APIManager()
        
        //Get data from UserDefaults add to Map
        getData()
        loadDataToMap()
        self.ipAddressSingleTextField.addTarget(self, action:#selector(MapViewController.cloneText(sender:)), for:UIControlEvents.editingChanged)
        
        //Update number of pins saved on map
        updateNumberOfPinsToDisplay()
        
        
        //Create Keyboard ToolBar
        createKeyboardToolbar()
        
        // NotificationCenter observers
        NotificationCenter.default.addObserver(self, selector: #selector(self.addAnnotationToMap(_:)), name: NSNotification.Name(rawValue: "HaveGoodIPAddress"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeSearchView(_:)), name: NSNotification.Name(rawValue: "CloseSearchView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.badIPAddressAlert(_:)), name: NSNotification.Name(rawValue: "HaveBadIPAddress"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removePinFromMap(_:)), name: NSNotification.Name(rawValue: "RemovePinFromMap"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNumberOfPinsToDisplay), name: NSNotification.Name(rawValue: "UpdateNumberOfPinsToDisplay"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Apply Shadows to Buttons and UIViews
        applyShadow(object: searchView)
        applyShadow(object: currentLocationButton)
        applyShadow(object: listViewButton)
        applyShadow(object: ipAddressesInfoView)
        //Update number of pins saved on map
        updateNumberOfPinsToDisplay()
    }

    
    // MARK: MapView Delegate Methods
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MapPin
        {
            let identifier = annotation.title
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier!) as? MKPinAnnotationView
            {
                view = dequeuedView
                view.annotation = annotation
            }
            else
            {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.animatesDrop = true
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                view.leftCalloutAccessoryView = UIButton(type: .custom)
                view.pinTintColor = UIColor(red: 9/255.0, green: 151/255.0, blue: 187/255.0, alpha: 1.0)
            }
            return view
        }
        return nil
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
                
                //Update Data and Display
                self.updateUserDefaults()
                let region = MKCoordinateRegionMakeWithDistance(newPin.coordinate, 2000, 2000)
                
                self.mapView.setRegion(region, animated: true)
                
            }
        }
        
    }
    
    func removePinFromMap(_ notification: NSNotification) {
        
        if let pinToRemove = notification.userInfo?["ipaddress"] as? IPAddress {
            
            let latitude = CLLocationDegrees((pinToRemove.latitude))
            let longitude = CLLocationDegrees((pinToRemove.longitude))
            let coordinates = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            let pin = MapPin(coordinate: coordinates, title: (pinToRemove.theIPAddress), subtitle: "\(pinToRemove.cityName), \(pinToRemove.regionName)")
            
            let annotations: [MKAnnotation] = self.mapView.annotations
            for _annotation in annotations {
                let annotation = _annotation
                let title = annotation.title!
                if title == pin.title! {
                    self.mapView.removeAnnotation(annotation)
                    
                    //Update Data and Display
                    self.updateUserDefaults()
                    print("\(title!) was deleted and removed from the map.")
                    break
                }
            }
        }
        
    }
    
    func updateUserDefaults() {
        self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: self.results), forKey: "PinsOnMap")
        if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
            self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
            print("Data saved in UserDefaults and results array updated.")
            self.updateNumberOfPinsToDisplay()
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
            searchLayoutHeight.constant = 160
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
                
                self.ipAddressesInfoView.isHidden = false
                UIView.animate(withDuration: 0.1, animations: {
                    
                    self.ipAddressesInfoView.alpha = 0
                    
                })
                
                if self.searchViewSegmentControl.selectedSegmentIndex == 1 {
                    
                    self.ipAddressRangeTextField.isHidden = false
                    self.ipaddressCloneTextField.isHidden = false
                    self.searchViewToLabel.isHidden = false
                    
                    self.ipaddressCloneTextField.alpha = 1
                    self.ipAddressRangeTextField.alpha = 1
                    self.searchViewToLabel.alpha = 1
                }
                
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
                
                self.ipAddressesInfoView.isHidden = false
                UIView.animate(withDuration: 0.7, animations: {
                    
                    self.ipAddressesInfoView.alpha = 1
                    
                })
                
                if self.searchViewSegmentControl.selectedSegmentIndex == 1 {
                
                    self.ipAddressRangeTextField.alpha = 0
                    self.searchViewToLabel.alpha = 0
                    self.ipaddressCloneTextField.alpha = 0
                }
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.searchViewButton.setImage(UIImage(named: "logoIcon.png"), for: .normal)
                self.searchViewSegmentControl.isHidden = true
                self.ipAddressSingleTextField.isHidden = true
                
                if self.searchViewSegmentControl.selectedSegmentIndex == 1 {
                
                    self.ipaddressCloneTextField.isHidden = true
                    self.ipAddressRangeTextField.isHidden = true
                    self.searchViewToLabel.isHidden = true
                }
            })

            
            searchViewActive = true
        }
        
    }
    
    func getData() {
        //Is their data saved in UserDefaults? Yes: retrieve No: create
        if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
            self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateNumberOfPinsToDisplay"), object: nil)
            print("I have data!")
        }else{
            self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: self.results), forKey: "PinsOnMap")
            if let data = self.defaults.object(forKey: "PinsOnMap") as? NSData {
                self.results = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Array<IPAddress>!
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateNumberOfPinsToDisplay"), object: nil)
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
    
    @IBAction func segmentControlChanged(_ sender: AnyObject) {
        
        switch searchViewSegmentControl.selectedSegmentIndex
        {
        case 0:
            ipAddressRangeTextField.isHidden = true
            ipaddressCloneTextField.isHidden = true
            searchViewToLabel.isHidden = true
            UIView.animate(withDuration: 0.7, animations: { 
                self.ipAddressRangeTextField.alpha = 0
                self.ipaddressCloneTextField.alpha = 0
                self.searchViewToLabel.alpha = 0
            })
            break
            
        case 1:
            ipAddressRangeTextField.isHidden = false
            ipaddressCloneTextField.isHidden = false
            searchViewToLabel.isHidden = false
            UIView.animate(withDuration: 0.7, animations: {
                self.ipAddressRangeTextField.alpha = 1
                self.ipaddressCloneTextField.alpha = 1
                self.searchViewToLabel.alpha = 1
            })
            break
            
        default:
            break;
        }
    }
    
    // A function that will only copy the text into th clone field up until it reaches the third decimal.
    func cloneText(sender: UITextField) {
        let userInput = sender.text!
        
        let arrayOfNumbers = userInput.components(separatedBy: ".")
        
        if arrayOfNumbers.count != 4 {
            self.ipaddressCloneTextField.text = "\(sender.text!)."
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
        ipAddressRangeTextField.inputAccessoryView = toolbar
        
    }
    
    func cancelKeyboard() {
        self.ipAddressSingleTextField.text = ""
        self.ipAddressRangeTextField.text = ""
        self.ipaddressCloneTextField.text = ""
        self.ipAddressSingleTextField.resignFirstResponder()
        self.ipAddressRangeTextField.resignFirstResponder()
    }
    
    func updateNumberOfPinsToDisplay() {
        self.numberOfPins.text = "\(self.results.count)"
    }
    
    func findIPOnMap() {
        
        switch searchViewSegmentControl.selectedSegmentIndex {
        case 0:
            let singleTextField = self.ipAddressSingleTextField.text
            self.ipAddressSingleTextField.text = ""
            self.ipAddressSingleTextField.resignFirstResponder()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CloseSearchView"), object: nil)
            var commaArray = [String]()
            commaArray = (singleTextField?.components(separatedBy: ","))!
            
                for ipAddress in commaArray {
                    self.client.findIPAddress(ipaddress: ipAddress)
            }
            break
        case 1:
            let firstTextField = self.ipAddressSingleTextField.text
            let targetNumber = self.ipAddressRangeTextField.text
            self.ipAddressSingleTextField.text = ""
            self.ipAddressSingleTextField.resignFirstResponder()
            self.ipAddressRangeTextField.text = ""
            self.ipAddressRangeTextField.resignFirstResponder()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CloseSearchView"), object: nil)
            
            DispatchQueue.global(qos: .background).async {
                // Create range of IP Addresses into an Array
                
                var array = firstTextField?.components(separatedBy: ".")
                let targetIntNumber = Int(targetNumber!)
                var startNumber = Int((array?.last!)!)
                array!.removeLast()
                var ipAddressRangeArray: [String] = [String]()
                var newIP: String = ""
                
                
                // Building IP Address Range Array
                while startNumber! <= targetIntNumber! {
                    
                    for number in array! {
                        let num = String(number)!
                        newIP.append("\(num).")
                    }
                    newIP.append("\(startNumber!)")
                    ipAddressRangeArray.append(newIP)
                    newIP.removeAll()
                    
                    startNumber = startNumber! + 1
                    
                }
                
                // Send each IPAddress in array to APIManager
                for ipAddress in ipAddressRangeArray {
                    
                    self.client.findIPAddress(ipaddress: ipAddress)
                    
                }
                self.ipIconImageView.isHidden = true
                self.pinsActivityIndicator.isHidden = false
            }
            break
        default:
            break
        }
    }
}
