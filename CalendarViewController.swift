//
//  CalendarViewController.swift
//  NamazPro
//
//  Created by al-insan on 15/06/17.
//  Copyright © 2017 al-insan. All rights reserved.
//

import UIKit

class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var lblCurrDate: UILabel!
    @IBOutlet weak var lblCurrLocation: UILabel!
    
    let preferences = UserDefaults.standard
    let keyForUserCity = "user_city"
    let keyForUserCountry = " user_country"
    let keyForUserCountryCode = "user_country_code"
    
    
    var user_city : String = "", user_country : String = "", user_country_code : String = ""
    
    var tblPrayerData : [String] = []
    
    let prayerColumnHeaders:[String] = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    
    // These two strings are the Identifiers set in the Storyboard
    let dateCellIdentifier = "DateCellIdentifier"
    let contentCellIdentifier = "ContentCellIdentifier"
    @IBOutlet weak var collectionView: UICollectionView!
    
    var arrMonthData : NSMutableArray = []
    
    var swipe_right_count : Int = 1, swipe_left_count : Int = 1
    
    let objCommonFunctions = CommonFunctions()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Code for Navigation
        let backToRootVCButton = UIBarButtonItem.init(title: "<", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backToMain))
        
        backToRootVCButton.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 30.0), NSForegroundColorAttributeName: UIColor.white], for: .normal)
        
        let titleLabel = UILabel(frame: CGRect(x:0, y:0, width:200, height:40))
        titleLabel.text = "Namaz Pro"
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        self.navigationItem.leftBarButtonItems = [backToRootVCButton, UIBarButtonItem(customView: titleLabel)]
        //Code for Navigation
        
        //code for collection view
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        //code for collection view
        
        //display date and location
        let now = NSDate()
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
        dateFormatter.dateFormat = "MMMM yyyy"
        let strCurrDate = dateFormatter.string(from: now as Date)
        self.lblCurrDate.text = /*Date().dayOfWeek()! + ", "+*/strCurrDate
        self.user_city = self.preferences.string(forKey: self.keyForUserCity)!
        self.user_country = self.preferences.string(forKey: self.keyForUserCountry)!
        self.user_country_code = self.preferences.string(forKey: self.keyForUserCountryCode)!
        self.lblCurrLocation.text = user_city+", "+user_country
        //display date and location
        
        //code for swipe gesture recognition
        let swipeLeft : UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(CalendarViewController.swipe(sender:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        
        let swipeRight : UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(CalendarViewController.swipe(sender:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        
        self.view.addGestureRecognizer(swipeLeft)
        self.view.addGestureRecognizer(swipeRight)
        //code for swipe gesture recognition
        
        //get current months data
        getCurrentMonthData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func swipe(sender: UISwipeGestureRecognizer) {
        
        let date = Date()
        let calendar = Calendar.current
        
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.right:
            //show previous month's calendar
            if swipe_right_count < 2{
                let previousMonthDate = calendar.date(byAdding: .month, value: -(swipe_right_count), to: date)
                swipe_right_count += 1
                swipe_left_count -= 1
                let year = calendar.component(.year, from: previousMonthDate!)
                let prevMonth = calendar.component(.month, from: previousMonthDate!)
                self.getCalendarForMonth(year: year, month: prevMonth, seekingDate: previousMonthDate!)
            }
            
        case UISwipeGestureRecognizerDirection.left:
            //show next month's calendar
            if swipe_left_count < 2{
                let nextMonthDate = calendar.date(byAdding: .month, value: swipe_left_count, to: date)
                swipe_left_count += 1
                swipe_right_count -= 1
                let year = calendar.component(.year, from: nextMonthDate!)
                let nextMonth = calendar.component(.month, from: nextMonthDate!)
                self.getCalendarForMonth(year: year, month: nextMonth, seekingDate: nextMonthDate!)
            }
            
        default:
            break
        }
    }
    
    func getCurrentMonthData () {
        var monthlyPrayerData : NSMutableArray
        monthlyPrayerData = DBManager.shared.getCurrentMonthData()
        
        if (monthlyPrayerData.count == 0){
            //stop right here
            self.lblCurrDate.text = "No data found"
            self.lblCurrLocation.text = ""
        }else{
            for obj in monthlyPrayerData{
                self.tblPrayerData.append(obj as! String)
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func getCalendarForMonth(year: Int, month: Int, seekingDate: Date){
        
        self.tblPrayerData.removeAll()
        self.tblPrayerData = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let strCurrDate = dateFormatter.string(from: seekingDate as Date)
        self.lblCurrDate.text = strCurrDate
        
        
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "strings", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        if myDict == nil{
        }else{
            
            self.objCommonFunctions.showLoader(self.view, myTitle: "")
            
            var salat_url = myDict?.value(forKey: "salat_api_url") as! String
            salat_url += "?city=" + self.user_city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            salat_url += "&country=" + self.user_country_code + "&month=\(month)"
            salat_url += "&year=\(year)&method=1"
            
            self.objCommonFunctions.get_data_from_url(url: salat_url) { (response) in
                DispatchQueue.main.async {
                    
                    let json = self.dataToJSON(data: response) as! [String: AnyObject]
                    
                    let jsonData: Any? = json
                    
                    if jsonData == nil{
                        //data could not be otained. Flow stops here
                        self.lblCurrDate.text = "Unable to fetch data"
                        self.lblCurrLocation.text = ""
                        
                    }else{
                        
                        if let prayerData = json["data"] as? [[String : AnyObject]] {
                            
                            for pData in prayerData {
                                
                                let timestamp = pData["date"]?["timestamp"] as! String
                                
                                
                                let prayerDate = NSDate(timeIntervalSince1970: self.objCommonFunctions.parseDuration(timestamp))
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd"
                                
                                let strPrayerDate = dateFormatter.string(from: prayerDate as Date)
                                
                                let arrFajrTime = (pData["timings"]?["Fajr"] as! String).components(separatedBy: " ")
                                
                                let arrDhuhrTime = (pData["timings"]?["Dhuhr"] as! String).components(separatedBy: " ")
                                
                                let arrAsrTime = (pData["timings"]?["Asr"] as! String).components(separatedBy: " ")
                                
                                let arrMaghribTime = (pData["timings"]?["Maghrib"] as! String).components(separatedBy: " ")
                                
                                let arrIshaTime = (pData["timings"]?["Isha"] as! String).components(separatedBy: " ")
                                
                                var prayerInfo = strPrayerDate + "@@" + arrFajrTime[0] + "@@" + arrDhuhrTime[0] + "@@" + arrAsrTime[0]
                                prayerInfo += "@@" + arrMaghribTime[0] + "@@" + arrIshaTime[0]
                                
                                self.tblPrayerData.append(prayerInfo)
                                
                            }
                            
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                            
                        }else{
                            //data could not be otained. Flow stops here
                            self.lblCurrDate.text = "Unable to fetch data"
                            self.lblCurrLocation.text = ""
                        }
                    }
                    
                    self.objCommonFunctions.removeLoader(self.view)
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
    
    func backToMain() {
        let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "Root") as! ViewController
        self.navigationController?.pushViewController(mainViewController, animated: true)
    }
    
    // MARK - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return (self.tblPrayerData.count + 2)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // This is the first row
        if (indexPath as NSIndexPath).section == 0 {
            if (indexPath as NSIndexPath).row == 0 {
                // This is the first cell of the first row. Label it.
                let dateCell : DateCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: dateCellIdentifier, for: indexPath) as! DateCollectionViewCell
                dateCell.backgroundColor = UIColor.white
                dateCell.dateLabel.font = UIFont.systemFont(ofSize: 13)
                dateCell.dateLabel.textColor = UIColor.black
                dateCell.dateLabel.text = "Date"
                
                dateCell.dateLabel.textAlignment = .center
                dateCell.layer.borderWidth = 1
                
                return dateCell
            } else {
                // This is the rest of the first row.
                let contentCell : PrayerNameCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: contentCellIdentifier, for: indexPath) as! PrayerNameCollectionViewCell
                contentCell.prayerNameLabel.font = UIFont.systemFont(ofSize: 13)
                contentCell.prayerNameLabel.textColor = UIColor.black
                
                contentCell.prayerNameLabel.text = prayerColumnHeaders[(indexPath.row - 1)]
                
                if (indexPath as NSIndexPath).section % 2 != 0 {
                    contentCell.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
                } else {
                    contentCell.backgroundColor = UIColor.white
                }
                
                contentCell.layer.borderWidth = 1
                
                return contentCell
            }
        } else {
            let curr_section : Int  = (indexPath.section) - 1
            
            if self.tblPrayerData.indices.contains(curr_section) {
                let data = self.tblPrayerData[curr_section]
                var arrSplit = (data).components(separatedBy:"@@")
                
                // These are the remaining rows
                if (indexPath as NSIndexPath).row == 0 {
                    // This is the first column of each row.
                    let dateCell : DateCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: dateCellIdentifier, for: indexPath) as! DateCollectionViewCell
                    dateCell.dateLabel.font = UIFont.systemFont(ofSize: 13)
                    dateCell.dateLabel.textColor = UIColor.black
                    
                    dateCell.dateLabel.text = arrSplit[0]
                    
                    if (indexPath as NSIndexPath).section % 2 != 0 {
                        dateCell.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
                    } else {
                        dateCell.backgroundColor = UIColor.white
                    }
                    
                    dateCell.layer.borderWidth = 1
                    
                    return dateCell
                } else {
                    // These are all the remaining content cells (neither first column nor first row)
                    let contentCell : PrayerNameCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: contentCellIdentifier, for: indexPath) as! PrayerNameCollectionViewCell
                    contentCell.prayerNameLabel.font = UIFont.systemFont(ofSize: 13)
                    contentCell.prayerNameLabel.textColor = UIColor.black
                    contentCell.prayerNameLabel.text = arrSplit[indexPath.row]
                    
                    if (indexPath as NSIndexPath).section % 2 != 0 {
                        contentCell.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
                    } else {
                        contentCell.backgroundColor = UIColor.white
                    }
                    
                    contentCell.layer.borderWidth = 1
                    
                    return contentCell
                }
                
            }else{
                let dummyCell : PrayerNameCollectionViewCell = collectionView .dequeueReusableCell(withReuseIdentifier: contentCellIdentifier, for: indexPath) as! PrayerNameCollectionViewCell
                dummyCell.prayerNameLabel.text = ""
                dummyCell.backgroundColor = UIColor.white
                return dummyCell
            }
        }
    }
    
}
