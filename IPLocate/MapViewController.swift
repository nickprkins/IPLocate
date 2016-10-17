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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        let givenIP: String = "74.125.45.100"
        self.client = APIManager()
        self.client.findIPAddress(ipaddress: givenIP)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.addAnnotationToMap(_:)), name: NSNotification.Name(rawValue: "HaveGoodIPAddress"), object: nil)
    }
    
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
        
        
        
    }
    
    
    
    
    
}

