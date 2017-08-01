//
//  DBManager.swift
//  NamazPro
//
//  Created by al-insan on 03/05/17.
//  Copyright © 2017 al-insan. All rights reserved.
//

import UIKit

class DBManager: NSObject {
    
    static let shared: DBManager = DBManager()
    
    let filemgr = FileManager.default
    let databaseFileName = "prayer.db"
    var pathToDatabase: String!
    var database: FMDatabase!
    
    //table and column names
    let ALARM_MASTER = "alarm_master", ALARM_ID = "alarm_id", ALARM_TYPE = "alarm_type"
    let AZAAN_MASTER = "azaan_master", AZAAN_ID = "azaan_id", AZAAN_FILE = "azaan_file"
    let PRAYER_MASTER = "prayer_master", MASTER_ID = "master_id", PRAYER_DATE = "date_for"
    let PRAYER_INFO = "prayer_info", PRAYER_ID = "prayer_id", PRAYER_NAME = "prayer_name", PRAYER_TIME="prayer_time"
    
    //fixed prayer names/values
    let FAJR_TIME = "fajr",DHUHR_TIME = "dhuhr",ASR_TIME = "asr",MAGHRIB_TIME = "maghrib",ISHA_TIME = "isha"
    
    //fixed values for Alarm Master records
    let alarm_types:[String] = ["silent", "sound", "vibrate"]
    let DEFAULT_ALARM_ID = 2
    
    //fixed values for Azan Master records
    let azaan_files: [String] = ["azan1.mp3","azan2.mp3","azan3.mp3"]
    let DEFAULT_AZAAN_ID = 1
    
    //Shared Preference to determine if database created already
    let preferences = UserDefaults.standard
    let keyForDbCreation = "db_created"
    
    
    override init() {
        super.init()
        
        let documentsDirectory = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        pathToDatabase = documentsDirectory[0].appendingPathComponent(databaseFileName).path
        
    }
    
    func createDatabase() -> Bool {
        var created = false
        
        let createAlarmMaster = "CREATE TABLE IF NOT EXISTS " + ALARM_MASTER + " (" + ALARM_ID + " INTEGER PRIMARY KEY AUTOINCREMENT not null," + ALARM_TYPE + " TEXT not null)"
        
        let createAzaanMaster = "CREATE TABLE IF NOT EXISTS " + AZAAN_MASTER + " (" + AZAAN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT not null," + AZAAN_FILE + " TEXT not null)";
        
        let createPrayerMaster = "CREATE TABLE IF NOT EXISTS " + PRAYER_MASTER + " (" + MASTER_ID + " INTEGER PRIMARY KEY AUTOINCREMENT not null," + PRAYER_DATE + " TEXT not null," + PRAYER_ID + " INTEGER not null)";
        
        let createPrayerInfo = "CREATE TABLE IF NOT EXISTS " + PRAYER_INFO + " (" + PRAYER_ID + " INTEGER PRIMARY KEY AUTOINCREMENT not null," + PRAYER_NAME + " TEXT not null," + PRAYER_TIME + " TEXT not null," + ALARM_ID + " INTEGER not null," + AZAAN_ID + " INTEGER not null)";
        
        do{
            try database.executeUpdate(createAlarmMaster, values: nil)
        }catch{
            print(error.localizedDescription)
        }
        
        
        do{
            try database.executeUpdate(createAzaanMaster, values: nil)
        }catch{
            print(error.localizedDescription)
        }
        
        do{
            try database.executeUpdate(createPrayerMaster, values: nil)
        }catch{
            print(error.localizedDescription)
        }
        
        do{
            try database.executeUpdate(createPrayerInfo, values: nil)
        }catch{
            print(error.localizedDescription)
        }
        
        //insert alarm master table records
        for alarm in alarm_types{
            do{
                //insert into alarm master table
                let sqlInsrtAlarmMaster = "INSERT INTO "+ALARM_MASTER  + "("+ALARM_TYPE+") VALUES (?)"
                
                try database.executeUpdate(sqlInsrtAlarmMaster, values: [alarm])
            }catch{
                print("Error: \(database.lastErrorMessage())")
            }
            
        }
        
        
        //insert master records into azaan master table
        for azaan_file in azaan_files{
            do{
                try database.executeUpdate("INSERT INTO "+AZAAN_MASTER + "("+AZAAN_FILE+") VALUES (?) ", values: [azaan_file])
            }catch{
                print("Error: \(database.lastErrorMessage())")
            }
        }
        
        
        
        
        
        created = true
        
        return created
    }
    
    func openDatabase() -> Bool {
        if !filemgr.fileExists(atPath: pathToDatabase as String) {
            self.database = FMDatabase(path: pathToDatabase as String)
            
            if self.database == nil {
                print("Error: \(self.database?.lastErrorMessage())")
                return false
            }
            
        }else{
            self.database = FMDatabase(path: pathToDatabase as String)
        }
        
        if self.database.open(){
            
            if preferences.object(forKey: keyForDbCreation) == nil {
                //DB  doesn't exist
                
                if self.createDatabase(){
                    //write to shared preference
                    preferences.set(true, forKey: keyForDbCreation)
                    preferences.synchronize()
                }else{
                    print("unable to create database!")
                }
            }
            
            return true
        }else{
            print("database file could not be created")
            return false
        }
    }
    
    func closeDatabase(){
        if self.database != nil {
            self.database.close()
        }
    }
    
    func deleteOldRecords()
    {
        if openDatabase() {
            
            do{
                
                //Delete from Prayer Info table
                let delPrayerInfo = "DELETE FROM \(self.PRAYER_INFO)"
                try self.database.executeQuery(delPrayerInfo, values: nil)
                
                //To reset the auto increament column
                let delPrayerInfoSequnce = "DELETE FROM  sqlite_sequence where name='\(self.PRAYER_INFO)'"
                try self.database.executeQuery(delPrayerInfoSequnce, values: nil)
                
                
                //Delet from Prayer master table
                let delPrayerMaster = "DELETE FROM \(self.PRAYER_MASTER)"
                try self.database.executeQuery(delPrayerMaster, values: nil)
                
                let delPrayerMasterSequnce = "DELETE FROM  sqlite_sequence where name='\(self.PRAYER_MASTER)'"
                try self.database.executeQuery(delPrayerMasterSequnce, values: nil)
                
                self.database.close()
                
            }catch{
                print(error.localizedDescription)
                
            }
        }
    }
    
    func getPrayerDataToday() -> NSMutableArray{
        let arrPrayerInfo : NSMutableArray = NSMutableArray()
        
        // Open the database.
        if openDatabase(){
            
            let strQuery = "SELECT m.*,i."+PRAYER_NAME+",i."+PRAYER_TIME+",i."+ALARM_ID+",i."+AZAAN_ID+",a."+ALARM_TYPE+",z."+AZAAN_FILE+" FROM "+PRAYER_MASTER+" m JOIN "+ALARM_MASTER+" a ON a."+ALARM_ID+"=i."+ALARM_ID+" JOIN "+AZAAN_MASTER+" z ON z."+AZAAN_ID+"=i."+AZAAN_ID+" JOIN "+PRAYER_INFO+" i ON i."+PRAYER_ID+"=m."+PRAYER_ID+" WHERE m."+PRAYER_DATE+" = date('now') ORDER BY m."+MASTER_ID
            
            var resultSet: FMResultSet? = nil
            
            do{
                resultSet = try self.database.executeQuery(strQuery, values: nil)
            }catch{
                print("Error: \(self.database.lastErrorMessage())")
            }
            
            
            if (resultSet != nil) {
                while (resultSet?.next())! {
                    let prayerInfo : PrayerInfo = PrayerInfo()
                    
                    prayerInfo.PRAYER_ID = Int((resultSet?.int(forColumn: PRAYER_ID))!)
                    prayerInfo.PRAYER_TIME = (resultSet?.string(forColumn: PRAYER_TIME))!
                    prayerInfo.PRAYER_DATE = (resultSet?.string(forColumn: PRAYER_DATE))!
                    prayerInfo.PRAYER_NAME = (resultSet?.string(forColumn: PRAYER_NAME))!
                    
                    let id = Int((resultSet?.int(forColumn: ALARM_ID))!)
                    
                    var strDataAlarmType : String = ""
                    
                    do{
                        var sqlFetchAlarmType = "SELECT \(self.ALARM_TYPE) FROM \(self.ALARM_MASTER) "
                        sqlFetchAlarmType += " WHERE \(self.ALARM_ID) = '\(id)'"
                        
                        var resultSetId: FMResultSet? = nil
                        
                        resultSetId = try self.database.executeQuery(sqlFetchAlarmType, values: nil)
                        
                        if (resultSetId != nil)
                        {
                            while (resultSetId?.next())! {
                                strDataAlarmType = String((resultSetId?.string(forColumn: ALARM_TYPE))!)
                            }
                            
                            prayerInfo.ALARM_TYPE = strDataAlarmType
                            
                        }
                        else{
                            prayerInfo.ALARM_TYPE = alarm_types[id]
                        }
                        
                    }
                    catch{
                        prayerInfo.ALARM_TYPE = alarm_types[id]
                    }
                    
                    prayerInfo.ALARM_ID = Int((resultSet?.int(forColumn: ALARM_ID))!)
                    prayerInfo.AZAAN_ID = Int((resultSet?.int(forColumn: AZAAN_ID))!)
                    prayerInfo.AZAAN_FILE = (resultSet?.string(forColumn: AZAAN_FILE))!
                    
                    arrPrayerInfo.add(prayerInfo)
                }
            }
            
            self.database.close()
            
        }
        
        return arrPrayerInfo
    }
    
    func prayerDataForDateAlready(strDate: String) -> Bool{
        // Open the database.
        if openDatabase(){
            
            let strQuery = "SELECT m.* FROM "+PRAYER_MASTER+" m WHERE m."+PRAYER_DATE+" = '\(strDate)'"
            
            var resultSet: FMResultSet? = nil
            
            do{
                resultSet = try self.database.executeQuery(strQuery, values: nil)
            }catch{
                print("Error: \(self.database.lastErrorMessage())")
            }
            
            if (resultSet != nil) {
                
                while (resultSet?.next())! {
                    if (resultSet?.string(forColumn: PRAYER_DATE))! == strDate{
                        return true
                    }
                }
                
                self.database.close()
                
                return false
                
            }else{
                self.database.close()
                return false
            }
            
        }else{
            self.database.close()
            return false
        }
        
        
    }
    
    func addPrayerData(arrObj: [PrayerInfo]) -> Bool
    {
        var bReturnResponse: Bool = false
        
        if openDatabase() {
            //first insert into PRAYER_INFO table
            if let queue =  FMDatabaseQueue(path: pathToDatabase) {
                queue.inTransaction() {
                    db, rollback in
                    
                    do{
                        
                        for obj in arrObj {
                            
                            //insert into alarm master table
                            var sqlInsrtPrayerInfo = "INSERT INTO "+self.PRAYER_INFO
                            sqlInsrtPrayerInfo += "("+self.PRAYER_NAME+","+self.PRAYER_TIME+","+self.ALARM_ID+","+self.AZAAN_ID+")"
                            sqlInsrtPrayerInfo += "VALUES (?,?,?,?)"
                            
                            try db?.executeUpdate(sqlInsrtPrayerInfo, values: [obj.PRAYER_NAME,obj.PRAYER_TIME,self.DEFAULT_ALARM_ID, self.DEFAULT_AZAAN_ID])
                            
                            //get the inserted id as prayer id
                            let inserted_prayer_id = db?.lastInsertRowId()
                            
                            if inserted_prayer_id! > 0{
                                
                                //insert into PRAYER_MASTER table
                                var strInsrtPrayerMaster = "INSERT INTO "+self.PRAYER_MASTER
                                strInsrtPrayerMaster += "("+self.PRAYER_DATE+","+self.PRAYER_ID+")"
                                strInsrtPrayerMaster += "VALUES (?,?)"
                                
                                
                                try db?.executeUpdate(strInsrtPrayerMaster, values: [obj.PRAYER_DATE,inserted_prayer_id!])
                                
                                let inserted_master_id = db?.lastInsertRowId()
                                
                                if inserted_master_id! > 0{
                                    continue
                                }else{
                                    rollback?.pointee = true
                                    bReturnResponse = false
                                    break
                                }
                                
                            }else{
                                rollback?.pointee = true
                                bReturnResponse = false
                                break
                            }
                        }
                        
                        
                        bReturnResponse = true
                        
                    }catch{
                        //rollback transactions
                        rollback?.pointee = true
                        bReturnResponse = false
                        print("Error: \(self.database.lastErrorMessage())")
                        
                    }
                    
                }
            }
            
            self.database.close()
            
        }else{
            print("database not opened")
            bReturnResponse = false
        }
        
        return bReturnResponse
        
    }
    
    func updateAlarmType(strPrayerName: String, strAlarmType: String)
    {
        if openDatabase() {
            
            do{
                
                var sqlFetchAlarmId = "SELECT \(self.ALARM_ID) FROM \(self.ALARM_MASTER) "
                sqlFetchAlarmId += " WHERE \(self.ALARM_TYPE) = '\(strAlarmType)'"
                
                var resultSet: FMResultSet? = nil
                
                resultSet = try self.database.executeQuery(sqlFetchAlarmId, values: nil)
                
                if (resultSet != nil)
                {
                    var alaramTypeId : Int = 0
                    
                    while (resultSet?.next())! {
                        alaramTypeId = Int((resultSet?.int(forColumn: ALARM_ID))!)
                    }
                    
                    var sqlInsrtPrayerInfo = "UPDATE "+self.PRAYER_INFO + " SET " + self.ALARM_ID + " = \(alaramTypeId)"
                    sqlInsrtPrayerInfo += " WHERE \(self.PRAYER_NAME) = '\(strPrayerName)' "
                    
                    try self.database.executeUpdate(sqlInsrtPrayerInfo, values: nil)
                    
                    self.database.close()
                    
                }
                
            }catch{
                print(error.localizedDescription)
            }
            
            
            
        }
    }
    
    func getAdhans() -> NSMutableArray
    {
        let arrAdhans : NSMutableArray = NSMutableArray()
        
        if openDatabase(){
            let strQuery = "SELECT * FROM "+AZAAN_MASTER
            
            var resultSet: FMResultSet? = nil
            
            do{
                resultSet = try self.database.executeQuery(strQuery, values: nil)
                
                
                if (resultSet != nil) {
                    while (resultSet?.next())! {
                        
                        let str = (resultSet?.string(forColumn: self.AZAAN_FILE))!
                        
                        var arrSplit = (str).components(separatedBy:".mp3")
                        
                        arrAdhans.add(arrSplit[0])
                    }
                }
                
            }catch{
                print("Error: \(self.database.lastErrorMessage())")
            }
        }else{
            
        }
        
        return arrAdhans
    }
    
    func getCurrentMonthData() -> NSMutableArray
    {
        let arrMonthData : NSMutableArray = NSMutableArray()
        
        if openDatabase(){
            var  strQuery = "SELECT m."+PRAYER_DATE+",Group_Concat(i."+PRAYER_TIME+",'@@') as prayer_times "
            strQuery += " FROM "+PRAYER_MASTER+" m "
            strQuery += " JOIN "+PRAYER_INFO+" i ON i."+PRAYER_ID+" = m."+PRAYER_ID
            strQuery += " WHERE strftime('%m',m."+PRAYER_DATE+") = strftime('%m',date('now'))"
            strQuery += " AND strftime('%Y',m."+PRAYER_DATE+") = strftime('%Y',date('now')) group by "+PRAYER_DATE
            
            var resultSet: FMResultSet? = nil
            
            do{
                resultSet = try self.database.executeQuery(strQuery, values: nil)
                
                
                if (resultSet != nil) {
                    while (resultSet?.next())! {
                        
                        let prayerInfo = (resultSet?.string(forColumn: PRAYER_DATE))! + "@@" + (resultSet?.string(forColumn: "prayer_times"))!
                        
                        arrMonthData.add(prayerInfo)
                    }
                }
                
            }catch{
                print("Error: \(self.database.lastErrorMessage())")
            }
        }else{
            
        }
        
        return arrMonthData

    }
    
    func getNextPrayerData()-> String{
        var strNextPrayerDateTime: String = ""
        
        // Open the database.
        if openDatabase(){
            
            let strQueryToday = "SELECT m.*,i."+PRAYER_NAME+",i."+PRAYER_TIME+",i."+ALARM_ID+",i."+AZAAN_ID+",a."+ALARM_TYPE+",z."+AZAAN_FILE+" FROM "+PRAYER_MASTER+" m JOIN "+ALARM_MASTER+" a ON a."+ALARM_ID+"=i."+ALARM_ID+" JOIN "+AZAAN_MASTER+" z ON z."+AZAAN_ID+"=i."+AZAAN_ID+" JOIN "+PRAYER_INFO+" i ON i."+PRAYER_ID+"=m."+PRAYER_ID+" WHERE m."+PRAYER_DATE+" = date('now') AND strftime('%H:%M',DATETIME(CURRENT_TIMESTAMP, 'LOCALTIME')) < strftime('%H:%M',i."+PRAYER_TIME+") ORDER BY m."+MASTER_ID + " LIMIT 1"
            
            var resultSetToday: FMResultSet? = nil
            
            do{
                resultSetToday = try self.database.executeQuery(strQueryToday, values: nil)
            }catch{
                print("Error: \(self.database.lastErrorMessage())")
            }
            
            if (resultSetToday != nil) {
                while (resultSetToday?.next())! {
                    
                    strNextPrayerDateTime = (resultSetToday?.string(forColumn: PRAYER_NAME))!+"@@"+(resultSetToday?.string(forColumn: PRAYER_DATE))!+"@@"+(resultSetToday?.string(forColumn: PRAYER_TIME))!
                }
            }
            
            if (strNextPrayerDateTime.isEmpty) {
                //check for tomorrow
                let strQueryTomorrow = "SELECT m.*,i."+PRAYER_NAME+",i."+PRAYER_TIME+",i."+ALARM_ID+",i."+AZAAN_ID+",a."+ALARM_TYPE+",z."+AZAAN_FILE+" FROM "+PRAYER_MASTER+" m JOIN "+ALARM_MASTER+" a ON a."+ALARM_ID+"=i."+ALARM_ID+" JOIN "+AZAAN_MASTER+" z ON z."+AZAAN_ID+"=i."+AZAAN_ID+" JOIN "+PRAYER_INFO+" i ON i."+PRAYER_ID+"=m."+PRAYER_ID+" WHERE m."+PRAYER_DATE+" = date('now','+1 day')  ORDER BY m."+MASTER_ID + " LIMIT 1"
                
                var resultSetTomorrow: FMResultSet? = nil
                
                do{
                    resultSetTomorrow = try self.database.executeQuery(strQueryTomorrow, values: nil)
                }catch{
                    print("Error: \(self.database.lastErrorMessage())")
                }
                
                
                if (resultSetToday != nil) {
                    while (resultSetTomorrow?.next())! {
                        
                        strNextPrayerDateTime = (resultSetTomorrow?.string(forColumn: PRAYER_NAME))!+"@@"+(resultSetTomorrow?.string(forColumn: PRAYER_DATE))!+"@@"+(resultSetTomorrow?.string(forColumn: PRAYER_TIME))!
                    }
                }
            }
            
            self.database.close()
            
        }
        
        return strNextPrayerDateTime
    }
    
    func getCurrDateTime()->String
    {
        var strDateTime: String = ""
        if openDatabase() {
            
            let strQuery = "select datetime('now') as now"
            
            var resultSet: FMResultSet? = nil
            
            do{
                resultSet = try self.database.executeQuery(strQuery, values: nil)
            }catch{
                print("Error: \(self.database.lastErrorMessage())")
            }
            
            
            if (resultSet != nil) {
                while (resultSet?.next())! {
                    
                    strDateTime = (resultSet?.string(forColumn: "now"))!
                }
            }
            
            self.database.close()
        }
        
        return strDateTime
        
    }
    
}
