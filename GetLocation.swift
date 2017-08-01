//
//  GetLocation.swift
//  NamazPro
//
//  Created by al-insan on 05/05/17.
//  Copyright © 2017 al-insan. All rights reserved.
//

import Foundation
import MapKit

struct Typealiases {
    typealias JSONDict = [String:Any]
}

class GetLocation{
    
    var currentLocation: CLLocation!
    
    var obtainedAddress:String = ""
    
    var bLocationObtained : Bool = false
    
    func getAddress(locManager: CLLocationManager, completion: @escaping (Typealiases.JSONDict) -> ()) {
        print("inside get location")
        
        
        
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            
            print("permission granted")
            
            currentLocation = locManager.location
            
            if currentLocation != nil {
                let geoCoder = CLGeocoder()
                geoCoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) -> Void in
                    
                    if error != nil {
                        var errorDict : [AnyHashable: Any]
                        errorDict = ["geocode_error":error!]
                        completion(errorDict as! Typealiases.JSONDict)
                        
                    } else {
                        
                        let placeArray = placemarks as [CLPlacemark]!
                        var placeMark: CLPlacemark!
                        placeMark = placeArray?[0]
                        completion(placeMark.addressDictionary as! Typealiases.JSONDict)
                    }
                }
            }
        }else{
            var errorDict : [AnyHashable: Any]
            errorDict = ["geocode_error":"permission denied"]
            completion(errorDict as! Typealiases.JSONDict)
        }
    }
}
