//
//  CommonFunctions.swift
//  NamazPro
//
//  Created by al-insan on 29/04/17.
//  Copyright © 2017 al-insan. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

class CommonFunctions{
    
    /*Variables for loading animation starts*/
    var actView: UIView = UIView()
    var loadingView: UIView = UIView()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var loadingTitleLabel: UILabel = UILabel()
    /*Variables for loading animation ends*/
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    func showLoader(_ myView: UIView, myTitle: String) {
        myView.isUserInteractionEnabled = false
        myView.window?.isUserInteractionEnabled = false
        myView.endEditing(true)
        actView.frame = CGRect(x: 0, y: 0, width: myView.frame.width, height: myView.frame.height)
        actView.center = myView.center
        actView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = myView.center
        loadingView.backgroundColor = UIColor.blue
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 15
        
        activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2);
        
        loadingTitleLabel.frame = CGRect(x: 5, y: loadingView.frame.height-20, width: loadingView.frame.width-10, height: 20)
        loadingTitleLabel.textColor = UIColor.white
        loadingTitleLabel.adjustsFontSizeToFitWidth = true
        loadingTitleLabel.textAlignment = NSTextAlignment.center
        loadingTitleLabel.text = myTitle
        loadingTitleLabel.font = UIFont.boldSystemFont(ofSize: 10)
        
        loadingView.addSubview(activityIndicator)
        actView.addSubview(loadingView)
        loadingView.addSubview(loadingTitleLabel)
        myView.addSubview(actView)
        activityIndicator.startAnimating()
    }
    
    func removeLoader(_ myView: UIView) {
        myView.isUserInteractionEnabled = true
        myView.window?.isUserInteractionEnabled = true
        activityIndicator.stopAnimating()
        actView.removeFromSuperview()
    }
    
    func get_data_from_url(url:String,completion: @escaping (Data) -> ()) {
        let requestURL: NSURL = NSURL(string: url)!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        var dataTask = URLSessionDataTask()
        let session = URLSession.shared
        dataTask = session.dataTask(with: urlRequest as URLRequest) { (data, response, error) in
            if (error == nil) {
                completion(data!)
            } else {
                // handle an error
                print("Ajax call error: \(error)")
            }
        }
        dataTask.resume()
    }
    
    
    func parseDuration(_ timeString:String) -> TimeInterval {
        guard !timeString.isEmpty else {
            return 0
        }
        
        var interval:Double = 0
        
        let parts = timeString.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }
        
        return interval
    }
    
    func connectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    func createAssetUrl(forImageNamed name: String) -> URL? {
        
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(name).png")
        
        guard fileManager.fileExists(atPath: url.path) else {
            guard
                let image = UIImage(named: name),
                let data = UIImagePNGRepresentation(image)
                else { return nil }
            
            fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
            return url
        }
        
        return url
    }
}
