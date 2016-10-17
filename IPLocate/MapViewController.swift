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
    @IBOutlet var currentLocationButton: UIButton!
    @IBOutlet var ipAddressesInfoView: UIView!
    @IBOutlet var showAllPinsButton: UIButton!
    
    
    
    var client: APIManager!
    var results: Array<IPAddress>! = []
    var searchViewConstraintsInActive: Array<NSLayoutConstraint>! = []
    var searchViewConstraintsActive: Array<NSLayoutConstraint>! = []
    var searchViewActive: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MapView setup
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        // API Setup
        self.client = APIManager()
        
        // NotificationCenter observers
        NotificationCenter.default.addObserver(self, selector: #selector(self.addAnnotationToMap(_:)), name: NSNotification.Name(rawValue: "HaveGoodIPAddress"), object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        // Setup Search View Button Constraints for Active and InActive Taps
        let margins = view.layoutMarginsGuide
        
        let topConstraint = searchView.topAnchor.constraint(equalTo: margins.topAnchor, constant: 20)
        let leadingConstraint = searchView.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
        let widthInActiveConstraint = NSLayoutConstraint(item: searchView, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1.0, constant: 45)
        let heightInActiveConstraint = NSLayoutConstraint(item: searchView, attribute: .height, relatedBy: .equal, toItem: searchView, attribute: .width
            , multiplier: 1.0, constant: 1)
        
        searchViewConstraintsInActive.append(topConstraint)
        searchViewConstraintsInActive.append(widthInActiveConstraint)
        searchViewConstraintsInActive.append(heightInActiveConstraint)
        searchViewConstraintsInActive.append(leadingConstraint)
        
        
        view.addConstraints(searchViewConstraintsInActive)
        view.layoutIfNeeded()
        
        //Go ahead and setup Active Constraints when the button is tapped and search fields are present.
        let widthActiveConstraint = NSLayoutConstraint(item: searchView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.8, constant: 1)
        let heightActiveConstraint = NSLayoutConstraint(item: searchView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100)
        
        searchViewConstraintsActive.append(topConstraint)
        searchViewConstraintsActive.append(widthActiveConstraint)
        searchViewConstraintsActive.append(heightActiveConstraint)
        
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
            let newIPAddress = self.results.last
            let latitude = CLLocationDegrees((newIPAddress?.latitude)!)
            let longitude = CLLocationDegrees((newIPAddress?.longitude)!)
            let coordinates = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            let newPin = MapPin(coordinate: coordinates, title: (newIPAddress?.theIPAddress)!, subtitle: "\(newIPAddress!.cityName), \(newIPAddress!.countryName)")
            DispatchQueue.main.async {
               //This is run on the main queue, after the previous code in outer block
                self.mapView.addAnnotation(newPin)
            }
        }
        
    }
    
    @IBAction func findCurrentLocation(_ sender: AnyObject) {
        
        let userLocation = mapView.userLocation
        
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 2000, 2000)
        
        mapView.setRegion(region, animated: true)
        
    }
    
    @IBAction func changeSearchView(_ sender: AnyObject) {
        
        if searchViewActive {
            self.view.removeConstraints(searchViewConstraintsActive)
            UIView.animate(withDuration: 1.0, animations: { 
                self.view.addConstraints(self.searchViewConstraintsInActive)
                self.view.layoutIfNeeded()
            })
            searchViewActive = false
        }else{
            self.view.removeConstraints(searchViewConstraintsInActive)
            UIView.animate(withDuration: 1.0, animations: { 
                self.view.addConstraints(self.searchViewConstraintsActive)
                self.view.layoutIfNeeded()
            })
            searchViewActive = true
        }
        
    }
}

