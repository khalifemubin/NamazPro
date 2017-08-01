//
//  UYLNotificationDelegate.swift
//  NamazPro
//
//  Created by al-insan on 07/07/17.
//  Copyright © 2017 al-insan. All rights reserved.
//

import Foundation
import  UserNotifications
import UserNotificationsUI
import AVFoundation

class UYLNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    var audioPlayer = AVAudioPlayer()
    let preferences = UserDefaults.standard
    let requestIdentifier = "AzanRequest"
    let keyForAzan = "azan_selected"
    let keyForSavingNotificationTitle = "notification_title"
    let keyForSavingNotificationDateTime = "notification_datetime"
    let keyForTappingNotification = "notification_tapped" 
    
    func setUpNotification(strDataDateTime: String, strNotificationTitle: String/*, strNotificationBody: String*/)
    {
        var strSavedAzanFile: String!
        strSavedAzanFile = preferences.string(forKey: self.keyForAzan)
        
        if strSavedAzanFile.lowercased().range(of:"optional") != nil{
            let arrSplitFileName = strSavedAzanFile.components(separatedBy: "\"")
            strSavedAzanFile = arrSplitFileName[1]
        }
        
        strSavedAzanFile = strSavedAzanFile + "_preview.mp3"
        
        let strDateFormatter = DateFormatter()
        strDateFormatter.dateFormat = "EEEE, MMMM dd, yyyy h:mm:ss a"
        let anotherDateFormatter = DateFormatter()
        anotherDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dataDateFormatter = DateFormatter()
        dataDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let strDateTimeForNotification = strDataDateTime+":00"
        let dataTime = dataDateFormatter.date(from: strDateTimeForNotification)
        
        //Save for app quit or device reboot. To be used in AppDelegate
        preferences.set(strNotificationTitle, forKey: self.keyForSavingNotificationTitle)
        preferences.set(strDataDateTime, forKey: self.keyForSavingNotificationDateTime)
        preferences.synchronize()
        
        let content = UNMutableNotificationContent()
        content.title = strNotificationTitle
        content.subtitle = " "
        content.body = " "
        content.sound = UNNotificationSound.init(named: strSavedAzanFile)
        
        //To Present image in notification
        if let path = Bundle.main.path(forResource: "notification_icon", ofType: "png") {
            let url = URL(fileURLWithPath: path)
            
            do {
                let attachment = try UNNotificationAttachment(identifier: "sampleImage", url: url, options: nil)
                content.attachments = [attachment]
            } catch {
                print("attachment not found.")
            }
        }
        
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: dataTime!)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,repeats: false)
        let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().add(request){(error) in
            
            if (error != nil){
                print(error!.localizedDescription)
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //Get next namaz info
        let nextPrayerInfo = DBManager.shared.getNextPrayerData()
        
        if !(nextPrayerInfo.isEmpty){
            //Schedule the next notification here
            var arrSplit = (nextPrayerInfo).components(separatedBy:"@@")
            
            let strDataDateTime: String = arrSplit[1]+" "+arrSplit[2]
            
            let strNotificationTitle = "Time for "+arrSplit[0]+" namaz"
            
            preferences.set(strNotificationTitle, forKey: self.keyForSavingNotificationTitle)
            preferences.set(strDataDateTime, forKey: self.keyForSavingNotificationDateTime)
            preferences.synchronize()
            
            self.setUpNotification(strDataDateTime: strDataDateTime, strNotificationTitle: strNotificationTitle)
        }
        
        completionHandler( [.alert,.sound,.badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        preferences.set("yes", forKey: self.keyForTappingNotification)
        preferences.synchronize()
        
        let obj = ViewController();
        obj.viewDidLoad()
        
        completionHandler()
    }
}
