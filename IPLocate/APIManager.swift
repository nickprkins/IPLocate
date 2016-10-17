//
//  APIManager.swift
//  IPLocate
//
//  Created by Nick Perkins on 10/14/16.
//  Copyright © 2016 Nick Perkins. All rights reserved.
//

import Foundation


class APIManager {
    
    var key: String
    var format: String
    var url: String
    var statusCode: Int = 0
    var baseUrl: NSURL
    
    
    
    required init() {
        self.key = "089038bc0a61ad5f771e4331a22bf1686923fef2d75ddeef17bd9491a82e6be2"
        self.format = "json"
        self.url = "https://api.ipinfodb.com/v3/ip-city/?"
        self.baseUrl = NSURL(string: "")!
    }
    
    
    func findIPAddress(ipaddress: String?) {
        // If nil, then return user's IP Address
        var userIP: Bool = false
        if ipaddress == nil {
            self.baseUrl = NSURL(string: "\(self.url)key=\(self.key)&format=\(self.format)")!
            userIP = true
        }else{
        self.baseUrl = NSURL(string: "\(self.url)key=\(self.key)&ip=\(ipaddress!)&format=\(self.format)")!
        }
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: baseUrl as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            self.statusCode = httpResponse.statusCode
            
            if (self.statusCode == 200) {
                
                do{
                    
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String:String]
                    
                    let newItem = IPAddress(dictionary: json as NSDictionary)
                    let data =  ["ipaddress" : newItem]
                    if userIP {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserIPAddress"), object: nil, userInfo: data)
                    }else{
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "HaveGoodIPAddress"), object: nil, userInfo: data)
                    }
                }catch {
                    print("Error with Json: \(error)")
                }
                
            }
            
        }
        task.resume()
    }
}
