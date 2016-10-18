//
//  IPAddress.swift
//  IPLocate
//
//  Created by Nick Perkins on 10/14/16.
//  Copyright © 2016 Nick Perkins. All rights reserved.
//

import Foundation


class IPAddress: NSObject, NSCoding {
    var dictionary: NSDictionary
    
    init(dictionary: NSDictionary) {
        self.dictionary = dictionary
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictionary = aDecoder.decodeObject(forKey: "dictionary") as? NSDictionary
            else { return nil }
        
        self.init(
            dictionary: dictionary
        )
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.dictionary, forKey: "dictionary")
    }
    
    var statusCode: String {
        get {
            return self.dictionary["statusCode"] as! String
        }
    }
    
    var statusMessage: String {
        get {
            return self.dictionary["statusMessage"] as! String
        }
    }
    
    var theIPAddress: String {
        get {
            return self.dictionary["ipAddress"] as! String
        }
    }
    
    var countryCode: String {
        get {
            return self.dictionary["countryCode"] as! String
        }
    }
    
    var countryName: String {
        get {
            return self.dictionary["countryName"] as! String
        }
    }
    
    var regionName: String {
        get {
            return self.dictionary["regionName"] as! String
        }
    }
    
    var cityName: String {
        get {
            return self.dictionary["cityName"] as! String
        }
    }
    
    var zipCode: String {
        get {
            return self.dictionary["zipCode"] as! String
        }
    }
    
    var latitude: String {
        get {
            return self.dictionary["latitude"] as! String
        }
    }
    
    var longitude: String {
        get {
            return self.dictionary["longitude"] as! String
        }
    }
    
    var timeZone: String {
        get {
            return self.dictionary["timeZone"] as! String
        }
    }
}
