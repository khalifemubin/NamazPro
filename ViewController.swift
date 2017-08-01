//
//  ViewController.swift
//  NamazPro
//
//  Created by al-insan on 27/04/17.
//  Copyright © 2017 al-insan. All rights reserved.
//

import UIKit
import MapKit
import  UserNotifications
//import UserNotificationsUI //framework to customize the notification*/
import AVFoundation

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension Date {
    func dayOfWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
        // or use capitalized(with: locale) if you want
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var locManager : CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        _locationManager.activityType = .automotiveNavigation
        _locationManager.distanceFilter = 10.0
        
        return _locationManager
    }()
    
    let loc = GetLocation()
    
    var user_city:String="",user_country:String="",user_country_code:String=""
    
    @IBOutlet weak var lblUserLocation: UILabel!
    @IBOutlet weak var lblCurrDateTime: UILabel!
    
    @IBOutlet weak var lblUpcomingPrayerTime: UILabel!
    @IBOutlet weak var lblUpcomingPrayerName: UILabel!
    
    @IBOutlet weak var tblPrayers: UITableView!
    
    
    @IBOutlet weak var btnFullAzan: UIButton!
    @IBOutlet weak var sliderFullAzan: UISlider!
    
    let objCommonFunctions = CommonFunctions()
    
    let preferences = UserDefaults.standard
    let keyForUserCity = "user_city"
    let keyForUserCountry = " user_country"
    let keyForUserCountryCode = "user_country_code"
    
    var tblPrayerData = [TablePrayerData]()
    
    let requestIdentifier = "AzanRequest"
    
    let keyForAzan = "azan_selected"
    let keyForSavingNotificationTitle = "notification_title"
    let keyForSavingNotificationDateTime = "notification_datetime"
    let keyForTappingNotification = "notification_tapped"
    
    var audioPlayer = AVAudioPlayer()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        btnFullAzan.isHidden = true
        sliderFullAzan.isHidden = true
        sliderFullAzan.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)
        
        if self.preferences.object(forKey: self.keyForAzan) != nil{
            
        }else{
            preferences.set("azan1", forKey: self.keyForAzan)
            preferences.synchronize()
        }
        
        objCommonFunctions.showLoader(self.view, myTitle: "")
        
        
        let titleLabel = UILabel(frame: CGRect(x:0, y:0, width:200, height:40))
        titleLabel.text = "Namaz Pro"
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        
        //add left bar button item
        let leftItem = UIBarButtonItem(customView: titleLabel)
        self.navigationItem.leftBarButtonItem = leftItem
        
        tblPrayers.separatorColor = UIColor.white
        
        
        //check if location saved. If not proceed
        if preferences.object(forKey: self.keyForUserCity) == nil {
            
            locManager.delegate = self
            
            if CLLocationManager.locationServicesEnabled() {
                if locManager.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization)) {
                    locManager.requestWhenInUseAuthorization()
                    locManager.startUpdatingLocation()
                } else {
                    self.displayPrayerData()
                }
            }
        }else{
            
            
            let now = NSDate()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
            let strCurrDate = dateFormatter.string(from: now as Date)
            
            self.lblCurrDateTime.text = strCurrDate
            
            self.user_city = self.preferences.string(forKey: self.keyForUserCity)!
            self.user_country = self.preferences.string(forKey: self.keyForUserCountry)!
            self.user_country_code = self.preferences.string(forKey: self.keyForUserCountryCode)!
            
            self.lblUserLocation.text = self.user_city+", "+self.user_country
            
            //directly go to display data
            self.displayPrayerData()
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToCalendar(tapGestureRecognizer:)))
        lblCurrDateTime.isUserInteractionEnabled = true
        lblCurrDateTime.addGestureRecognizer(tapGestureRecognizer)
        
        if let notification_tapped = self.preferences.string(forKey: self.keyForTappingNotification) {
            
            
            
            let alert = UIAlertController(title: "Notification value alert", message: "notification_tapped="+notification_tapped, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            
            self.parent?.present(alert, animated: true, completion: nil)
            
            if notification_tapped.lowercased() == "yes"{
                self.notificationTappedPlayAzan()
            }
        }
    }
    
    func getData(_ notification: Notification) {
        let alert = UIAlertController(title: "Get DAta Alert", message: "Got Notification", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if sliderFullAzan.value > 0 {
            audioPlayer.stop()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationObtainedProgress() {
        //first check if location already saved
        if preferences.object(forKey: keyForUserCity) == nil {
            let objNetworkCheck = NetworkCheck()
            
            if objNetworkCheck.connectedToNetwork(){

                loc.getAddress(locManager: locManager) {
                    result in
                    
                    if let city = result["City"] as? String {
                        self.user_city = city
                    }
                    
                    if let country = result["Country"] as? String{
                        self.user_country = country
                    }
                    
                    if let country_code = result["CountryCode"] as? String{
                        self.user_country_code = country_code
                    }
                    
                    
                    if let error_occured = result["geocode_error"] as? String{
                        print("geocode error obtained "+error_occured)
                    }
                    
                    if (self.user_city.isEmpty) || (self.user_country.isEmpty){
                        self.lblUserLocation.text = "Unable to get your location"
                        self.displayRestofUI(bDisplay: false)
                    }else{
                        
                        //write to shared preference
                        self.preferences.set(self.user_city, forKey: self.keyForUserCity)
                        self.preferences.set(self.user_country, forKey: self.keyForUserCountry)
                        self.preferences.set(self.user_country_code, forKey: self.keyForUserCountryCode)
                        self.preferences.synchronize()
                        
                        self.lblUserLocation.text = self.user_city+", "+self.user_country
                        self.displayRestofUI(bDisplay: true)
                    }
                }
            }else{
                self.lblUserLocation.text = "Unable to get your location"
                
                self.displayRestofUI(bDisplay: false)
            }
            
        }else{
            self.user_city = self.preferences.string(forKey: self.keyForUserCity)!
            self.user_country = self.preferences.string(forKey: self.keyForUserCountry)!
            self.user_country_code = self.preferences.string(forKey: self.keyForUserCountryCode)!
            
            self.lblUserLocation.text = self.user_city+", "+self.user_country
            self.displayRestofUI(bDisplay: true)
        }
        
    }
    
    func displayRestofUI(bDisplay:Bool){
        if bDisplay{
            
            let now = NSDate()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
            let strCurrDate = dateFormatter.string(from: now as Date)
            
            lblCurrDateTime.text = strCurrDate
            
            checkPayerData()
            
        }else{
            lblCurrDateTime.text = ""
            lblUpcomingPrayerName.text = ""
            lblUpcomingPrayerTime.text = ""
        }
        
    }
    
    func checkPayerData(){
        //check if data exists in database
        var todayPrayerData : NSMutableArray
        todayPrayerData = DBManager.shared.getPrayerDataToday()
        
        if (todayPrayerData.count == 0){
            //fetch prayer data for current month
            let date = Date()
            let calendar = Calendar.current
            
            let curr_month = calendar.component(.month, from: date)
            let curr_year = calendar.component(.year, from: date)
            fetchPrayerData(month:curr_month,year:curr_year)
        }
        else{
            displayPrayerData()
        }
    }
    
    func fetchPrayerData(month: Int, year: Int){
        
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "strings", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        if myDict == nil{
        }else{
            
            var strPrayerUrl = myDict?.value(forKey: "salat_api_url") as! String
            
            strPrayerUrl += "?city=" + self.user_city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            
            strPrayerUrl += "&country=" + self.user_country_code + "&month=\(month)"
            
            strPrayerUrl += "&year=" + String(year) + "&method=1";
            
            objCommonFunctions.get_data_from_url(url: strPrayerUrl) { (response) in
                
                let json = self.dataToJSON(data: response) as! [String: AnyObject]
                
                let jsonData: Any? = json
                
                if jsonData == nil{
                    //data could not be otained. Flow stops here
                    self.lblUpcomingPrayerTime.text=""
                    self.lblCurrDateTime.text = ""
                    self.lblUserLocation.text = "Unable to fetch data"
                    
                }else{
                    
                    if let prayerData = json["data"] as? [[String : AnyObject]] {
                        
                        //first delete old records
                        DBManager.shared.deleteOldRecords()
                        
                        var objPrayerLists = [PrayerInfo]()
                        
                        for pData in prayerData {
                            
                            let timestamp = pData["date"]?["timestamp"] as! String
                            
                            
                            let prayerDate = NSDate(timeIntervalSince1970: self.objCommonFunctions.parseDuration(timestamp))
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            
                            let strPrayerDate = dateFormatter.string(from: prayerDate as Date)
                            
                            if ( DBManager.shared.prayerDataForDateAlready(strDate: strPrayerDate)){
                                
                            }else{
                                
                                let arrFajrTime = (pData["timings"]?["Fajr"] as! String).components(separatedBy: " ")
                                
                                var insertObj = PrayerInfo()
                                insertObj.PRAYER_DATE = strPrayerDate
                                insertObj.PRAYER_NAME = "Fajr"
                                insertObj.PRAYER_TIME = arrFajrTime[0]
                                
                                //insert data for Fajr prayer
                                objPrayerLists.append(insertObj)
                                
                                
                                let arrDhuhrTime = (pData["timings"]?["Dhuhr"] as! String).components(separatedBy: " ")
                                insertObj = PrayerInfo()
                                insertObj.PRAYER_DATE = strPrayerDate
                                insertObj.PRAYER_NAME = "Dhuhr"
                                insertObj.PRAYER_TIME = arrDhuhrTime[0]
                                
                                //insert data for Dhuhr prayer
                                objPrayerLists.append(insertObj)
                                
                                
                                let arrAsrTime = (pData["timings"]?["Asr"] as! String).components(separatedBy: " ")
                                insertObj = PrayerInfo()
                                insertObj.PRAYER_DATE = strPrayerDate
                                insertObj.PRAYER_NAME = "Asr"
                                insertObj.PRAYER_TIME = arrAsrTime[0]
                                
                                //insert data for Asr prayer
                                objPrayerLists.append(insertObj)
                                
                                
                                let arrMaghribTime = (pData["timings"]?["Maghrib"] as! String).components(separatedBy: " ")
                                insertObj = PrayerInfo()
                                insertObj.PRAYER_DATE = strPrayerDate
                                insertObj.PRAYER_NAME = "Maghrib"
                                insertObj.PRAYER_TIME = arrMaghribTime[0]
                                
                                //insert data for Maghrib prayer
                                objPrayerLists.append(insertObj)
                                
                                
                                let arrIshaTime = (pData["timings"]?["Isha"] as! String).components(separatedBy: " ")
                                insertObj = PrayerInfo()
                                insertObj.PRAYER_DATE = strPrayerDate
                                insertObj.PRAYER_NAME = "Isha"
                                insertObj.PRAYER_TIME = arrIshaTime[0]
                                
                                //insert data for Isha prayer
                                objPrayerLists.append(insertObj)
                                
                                let dbResponse = DBManager.shared.addPrayerData(arrObj: objPrayerLists)
                                
                                objPrayerLists.removeAll()
                                
                                if dbResponse {
                                    continue
                                }else{
                                    DispatchQueue.main.async {
                                        self.lblUpcomingPrayerTime.text=""
                                        self.lblCurrDateTime.text = ""
                                        self.lblUserLocation.text = "Unable to fetch data"
                                    }
                                    
                                    break
                                }
                            }
                            
                        }
                        
                        self.displayPrayerData()
                        
                    }else{
                        //data could not be otained. Flow stops here
                        self.lblUpcomingPrayerTime.text=""
                        self.lblCurrDateTime.text = ""
                        self.lblUserLocation.text = "Unable to fetch data"
                        
                    }
                }
                
                
            }
        }
        
    }
    
    func dataToJSON(data: Data) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        } catch let myJSONError {
            print(myJSONError)
        }
        return nil
    }
    
    func displayPrayerData(){
        
        DispatchQueue.main.async {
            var todayPrayerData : NSMutableArray
            todayPrayerData = DBManager.shared.getPrayerDataToday()
            
            if (todayPrayerData.count == 0){
                self.lblUpcomingPrayerTime.text=""
                self.lblCurrDateTime.text = ""
                self.lblUserLocation.text = "Unable to fetch data"
                
                //fetch data for current month
                let date = Date()
                let calendar = Calendar.current
                
                let curr_month = calendar.component(.month, from: date)
                let curr_year = calendar.component(.year, from: date)
                self.fetchPrayerData(month: curr_month,year: curr_year)
                
                
            }else{
                let now = NSDate()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                
                dateFormatter.timeZone = NSTimeZone(name: self.user_country) as TimeZone!
                
                var secondsFromGMT: Double { return Double(TimeZone.current.secondsFromGMT()) }
                let strCurrDateTime = dateFormatter.string(from: now as Date)
                var currTime = dateFormatter.date(from: strCurrDateTime)
                currTime?.addTimeInterval(secondsFromGMT)
                
                var nextPrayerName : String = ""
                
                for obj in todayPrayerData{
                    let prayerObj : PrayerInfo = obj as! PrayerInfo
                    
                    let dataDateFormatter = DateFormatter()
                    dataDateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    dataDateFormatter.timeZone = NSTimeZone(name: self.user_country) as TimeZone!
                    
                    let strDataDate = dataDateFormatter.string(from: now as Date)
                    
                    let strDataDateTime = strDataDate + " " + prayerObj.PRAYER_TIME
                    
                    var dataTime = dateFormatter.date(from: strDataDateTime)
                    dataTime?.addTimeInterval(secondsFromGMT)
                    
                    if nextPrayerName.isEmpty {
                        
                        if(currTime! < dataTime!)
                        {
                            nextPrayerName = prayerObj.PRAYER_NAME
                            
                            self.lblUpcomingPrayerName.text = prayerObj.PRAYER_NAME
                            self.lblUpcomingPrayerTime.text = prayerObj.PRAYER_TIME
                            
                            //Schedule the next notification here
                            self.setUpNotification(strDataDateTime: strDataDateTime, strNotificationTitle: "Time for "+prayerObj.PRAYER_NAME+" namaz")
                        }
                        
                    }
                    
                    let tempPrayerData = TablePrayerData()
                    tempPrayerData.txtPrayerName = prayerObj.PRAYER_NAME
                    tempPrayerData.txtPrayerTime = prayerObj.PRAYER_TIME
                    tempPrayerData.imgAzanType = prayerObj.ALARM_TYPE
                    
                    self.tblPrayerData.append(tempPrayerData)
                }
                
                //Today's prayer times over. Fetch for tomorrow
                if nextPrayerName.isEmpty {
                    let nextPrayerInfo = DBManager.shared.getNextPrayerData()
                    
                    if nextPrayerInfo != ""{
                        
                        var arrSplit = (nextPrayerInfo).components(separatedBy:"@@")
                        
                        let strDataDateTime: String = arrSplit[1]+" "+arrSplit[2]
                        
                        //Also updated the ui with next prayer name and prayer time
                        self.lblUpcomingPrayerName.text = arrSplit[0]
                        self.lblUpcomingPrayerTime.text = arrSplit[2]
                        
                        self.setUpNotification(strDataDateTime: strDataDateTime, strNotificationTitle: "Time for "+arrSplit[0]+" namaz")
                    }else{
                        //fetch next month's data
                        let date = Date()
                        
                        var dateComponent = DateComponents()
                        dateComponent.month = 1
                        let futureDate = Calendar.current.date(byAdding: dateComponent, to: date)
                        
                        let calendar = Calendar.current
                        
                        let month = calendar.component(.month, from: futureDate!)
                        let year = calendar.component(.year, from: futureDate!)
                        self.fetchPrayerData(month: month,year: year)
                        
                    }
                }
                
                self.tblPrayers.reloadData()
                
            }
            
            self.objCommonFunctions.removeLoader(self.view)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if DBManager.shared.openDatabase(){
            
            let location:CLLocation = locations[locations.count-1]
            
            if (location.horizontalAccuracy > 0) {
                self.locManager.stopUpdatingLocation()
                
                DBManager.shared.closeDatabase()
                
                locManager = manager
                
                self.locationObtainedProgress()
            }
        }else{
            self.lblUpcomingPrayerTime.text=""
            self.lblCurrDateTime.text = ""
            self.lblUserLocation.text = "Unable to fetch data"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.lblUpcomingPrayerTime.text=""
        self.lblCurrDateTime.text = ""
        self.lblUserLocation.text = "Unable to fetch data"
        print(error.localizedDescription)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tblPrayerData.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "namazCell")!
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        
        let data = self.tblPrayerData[indexPath.row]
        
        let lblPrayerName : UILabel = cell.contentView.viewWithTag(10) as! UILabel
        lblPrayerName.text = data.txtPrayerName
        
        let lblPrayerTime : UILabel  = cell.contentView.viewWithTag(11) as! UILabel
        lblPrayerTime.text = data.txtPrayerTime
        
        let imgAlarmType : UIImageView = cell.contentView.viewWithTag(12) as! UIImageView
        
        imgAlarmType.image = UIImage(named: data.imgAzanType)
        
        imgAlarmType.accessibilityLabel = data.imgAzanType
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(updateAlarmType(tapGestureRecognizer:)))
        imgAlarmType.isUserInteractionEnabled = true
        imgAlarmType.addGestureRecognizer(tapGestureRecognizer)
        
        return cell
    }
    
    func updateAlarmType(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let sender = tapGestureRecognizer.view!
        let alarm_type = sender.accessibilityLabel!
        
        //using sender, we can get the point in respect to the table view
        let tapLocation = tapGestureRecognizer.location(in: tblPrayers)
        
        //using the tapLocation, we retrieve the corresponding indexPath
        let indexPath = tblPrayers.indexPathForRow(at: tapLocation)
        
        //we could even get the cell from the index, too
        let cell = tblPrayers.cellForRow(at: indexPath!)
        let lblPrayerName : UILabel = cell!.contentView.viewWithTag(10) as! UILabel
        
        let lblPrayerTime : UILabel  = cell!.contentView.viewWithTag(11) as! UILabel
        
        var update_alarm_type:String = ""
        
        switch alarm_type
        {
        case "sound":
            update_alarm_type = "silent"
            
        case "silent":
            update_alarm_type = "vibrate"
            
        case "vibrate":
            update_alarm_type = "sound"
            
        default:
            break
            
        }
        
        //update alarm type for that specific prayer throughout the calendar
        DBManager.shared.updateAlarmType(strPrayerName: lblPrayerName.text!, strAlarmType: update_alarm_type)
        
        let tempPrayerData = TablePrayerData()
        tempPrayerData.txtPrayerName = lblPrayerName.text!
        tempPrayerData.txtPrayerTime = lblPrayerTime.text!
        tempPrayerData.imgAzanType = update_alarm_type
        
        self.tblPrayerData[(indexPath?.row)!] = tempPrayerData
        
        self.tblPrayers.reloadData()
        
    }
    
    func goToCalendar(tapGestureRecognizer: UITapGestureRecognizer){
        let controller = storyboard?.instantiateViewController(withIdentifier: "CalendarVC")
        self.navigationController!.pushViewController(controller!, animated: true)
    }
    
    func setUpNotification(strDataDateTime: String, strNotificationTitle: String/*, strNotificationBody: String*/)
    {
        var strSavedAzanFile: String!
        strSavedAzanFile = preferences.string(forKey: self.keyForAzan)
        
        if strSavedAzanFile.lowercased().range(of:"optional") != nil{
            let arrSplitFileName = strSavedAzanFile.components(separatedBy: "\"")
            strSavedAzanFile = arrSplitFileName[1]
        }
        
        strSavedAzanFile = strSavedAzanFile + "_preview.mp3"
        
        let dataDateFormatter = DateFormatter()
        dataDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let arrSplitDateAndTime = strDataDateTime.components(separatedBy: " ")
        let arrSplitOnlyDate = arrSplitDateAndTime[0].components(separatedBy: "-")
        let arrSplitTimeOfDate = arrSplitDateAndTime[1].components(separatedBy: ":")
        
        var dateComponents = DateComponents()
        dateComponents.year = Int(arrSplitOnlyDate[0])!
        dateComponents.month = Int(arrSplitOnlyDate[1])!
        dateComponents.day = Int(arrSplitOnlyDate[2])!
        dateComponents.timeZone =  NSTimeZone.local
        dateComponents.hour = Int(arrSplitTimeOfDate[0])!
        dateComponents.minute = Int(arrSplitTimeOfDate[1])!
        dateComponents.second = 0
        
        
        // Create date from components
        //Save for app quit or device reboot. To be used in AppDelegate
        preferences.set(strNotificationTitle, forKey: self.keyForSavingNotificationTitle)
        preferences.set(strDataDateTime, forKey: self.keyForSavingNotificationDateTime)
        preferences.synchronize()
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents,repeats: false)
        
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
        
        let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().add(request){(error) in
            
            if (error != nil){
                
                print(error!.localizedDescription)
            }
        }
    }
    
    func updateSlider(_ timer: Timer){
        sliderFullAzan.value = Float(audioPlayer.currentTime)
        
        if sliderFullAzan.value == 0 {
            btnFullAzan.setImage(UIImage(named: "play_icon"), for: .normal)
        }
    }
    
    func sliderValueDidChange(sender:UISlider!)
    {
        if audioPlayer.isPlaying{
            audioPlayer.currentTime = TimeInterval(sender.value)
        }
    }
    
    
    func notificationTappedPlayAzan()
    {
        preferences.set("no", forKey: self.keyForTappingNotification)
        preferences.synchronize()
        
        //Notification clicked. Start playing full azan
        btnFullAzan.isHidden = false
        sliderFullAzan.isHidden = false
        
        var strSavedAzanFile: String!
        strSavedAzanFile = preferences.string(forKey: self.keyForAzan)
        
        if strSavedAzanFile.lowercased().range(of:"optional") != nil{
            let arrSplitFileName = strSavedAzanFile.components(separatedBy: "\"")
            strSavedAzanFile = arrSplitFileName[1]
        }
        
        strSavedAzanFile = strSavedAzanFile.capitalized
        
        //play audio file
        let path = Bundle.main.path(forResource: strSavedAzanFile, ofType: "mp3")
        
        if let path = path {
            let mp3Url = NSURL(fileURLWithPath: path)
            
            do{
                audioPlayer = try AVAudioPlayer(contentsOf: mp3Url as URL)
                audioPlayer.accessibilityLabel = strSavedAzanFile
                sliderFullAzan.maximumValue = Float(audioPlayer.duration)
                audioPlayer.play()
                
                btnFullAzan.setImage(UIImage(named: "pause_icon"), for: .normal)
                
                Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.updateSlider), userInfo: nil, repeats: true)
                
            }catch let error as NSError{
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func playPauseFullAzan(_ sender: Any)
    {
        var strSavedAzanFile: String!
        strSavedAzanFile = preferences.string(forKey: keyForAzan)
        
        if strSavedAzanFile.lowercased().range(of:"optional") != nil{
            let arrSplitFileName = strSavedAzanFile.components(separatedBy: "\"")
            strSavedAzanFile = arrSplitFileName[1]
        }
        
        if(btnFullAzan.imageView?.image == UIImage(named:"play_icon.png")){
            btnFullAzan.setImage(UIImage(named: "pause_icon"), for: .normal)
            
            let strResourceFile: String = strSavedAzanFile
            
            if (audioPlayer.currentTime > 0) {
                //resume
                audioPlayer.play()
            }else{
                //play audio file anew
                let path = Bundle.main.path(forResource: strResourceFile, ofType: "mp3")
                
                if let path = path {
                    let mp3Url = NSURL(fileURLWithPath: path)
                    
                    do{
                        
                        audioPlayer = try AVAudioPlayer(contentsOf: mp3Url as URL)
                        audioPlayer.accessibilityLabel = strResourceFile
                        sliderFullAzan.maximumValue = Float(audioPlayer.duration)
                        audioPlayer.play()
                        
                        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.updateSlider), userInfo: nil, repeats: true)
                        
                    }catch let error as NSError{
                        print(error.localizedDescription)
                    }
                }
                
            }
        }else{
            btnFullAzan.setImage(UIImage(named: "play_icon"), for: .normal)
            
            if audioPlayer.isPlaying{
                let time : TimeInterval = audioPlayer.currentTime
                audioPlayer.pause()
                audioPlayer.currentTime = time
            }
        }
    }
    
}

extension ViewController:UNUserNotificationCenterDelegate{
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //Get next namaz info
        let nextPrayerInfo = DBManager.shared.getNextPrayerData()
        
        if !(nextPrayerInfo.isEmpty){
            //Schedule the next notification here
            var arrSplit = (nextPrayerInfo).components(separatedBy:"@@")
            
            let strDataDateTime: String = arrSplit[1]+" "+arrSplit[2]
            
            
            //Also updated the ui with next prayer name and prayer time
            let strNotificationTitle = "Time for "+arrSplit[0]+" namaz"
            
            preferences.set(strNotificationTitle, forKey: self.keyForSavingNotificationTitle)
            preferences.set(strDataDateTime, forKey: self.keyForSavingNotificationDateTime)
            preferences.synchronize()
            
            self.setUpNotification(strDataDateTime: strDataDateTime, strNotificationTitle: strNotificationTitle)
        }
        
        // Play sound and show alert to the user
        completionHandler( [.alert,.sound,.badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        preferences.set("yes", forKey: self.keyForTappingNotification)
        preferences.synchronize()
        
        self.viewDidLoad()
        
        completionHandler()
    }
}
