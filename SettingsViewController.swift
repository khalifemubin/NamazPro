//
//  SettingsViewController.swift
//  NamazPro
//
//  Created by al-insan on 08/06/17.
//  Copyright © 2017 al-insan. All rights reserved.
//

import UIKit
import AVFoundation


class SettingsViewController: UIViewController , UITableViewDelegate, UITableViewDataSource{
    
    var arrAdhans : NSMutableArray = []
    
    @IBOutlet weak var audioProgress: UISlider!
    @IBOutlet weak var lblChooseAdhan: UILabel!
    @IBOutlet weak var lblSetting: UILabel!
    
    let preferences = UserDefaults.standard
    
    let keyForAzan = "azan_selected"
    
    @IBOutlet weak var tblAdhan: UITableView!
    
    var audioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let backToRootVCButton = UIBarButtonItem.init(title: "<", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backToMain))
        
        backToRootVCButton.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 30.0), NSForegroundColorAttributeName: UIColor.white], for: .normal)
        
        let titleLabel = UILabel(frame: CGRect(x:0, y:0, width:200, height:40))
        titleLabel.text = "Namaz Pro"
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        
        self.navigationItem.leftBarButtonItems = [backToRootVCButton, UIBarButtonItem(customView: titleLabel)]
        
        audioProgress.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)
        
        arrAdhans = DBManager.shared.getAdhans()
        
        if arrAdhans.count > 0 {
            lblSetting.isHidden = false
            lblChooseAdhan.isHidden = false
            tblAdhan.isHidden = false
        }else {
            lblSetting.isHidden = true
            lblChooseAdhan.isHidden = true
            tblAdhan.isHidden = true
        }
        
        tblAdhan.reloadData()
        
        //Remove extra blank cells
        tblAdhan.tableFooterView = UIView()
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backToMain() {
        let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "Root") as! ViewController
        self.navigationController?.pushViewController(mainViewController, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrAdhans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "adhanCell")!
        
        //To avoid cell highlight on tap
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        
        let data:String = self.arrAdhans[indexPath.row] as! String
        
        let lblAzanName : UILabel = cell.contentView.viewWithTag(10) as! UILabel
        let btnAzanSelection : UIButton = cell.contentView.viewWithTag(12) as! UIButton
        
        lblAzanName.text = data.capitalized
        
        //make default azan selected in case if none selected already
        if preferences.object(forKey: self.keyForAzan) == nil {
            if indexPath.row == 0{
                btnAzanSelection.setImage(UIImage(named: "checked"), for: .normal)
                btnAzanSelection.imageEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18)
            }
        }else{
            let strSavedAzanFile = (preferences.string(forKey: self.keyForAzan)!).lowercased()
            
            let rowAzanFile = (String(describing:lblAzanName.text)).lowercased()
            
            if strSavedAzanFile == rowAzanFile {
                btnAzanSelection.setImage(UIImage(named: "checked"), for: .normal)
                btnAzanSelection.imageEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18)
            }
        }
        
        btnAzanSelection.addTarget(self, action: #selector(setAzanFile), for: .touchUpInside)
        
        let btnPlayPause : UIButton = cell.contentView.viewWithTag(11) as! UIButton
        btnPlayPause.addTarget(self, action: #selector(playPauseAzan), for: .touchUpInside)
        
        
        return cell
    }
    
    func setAzanFile(_ sender: UIButton) {
        
        let cells = self.tblAdhan.visibleCells
        
        for cell in cells {
            let btnAzanSelection : UIButton = cell.viewWithTag(12) as! UIButton
            btnAzanSelection.setImage(UIImage(named: "unchecked"), for: .normal)
            btnAzanSelection.imageEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18)
        }
        
        if let cell = sender.superview?.superview as? UITableViewCell {
            
            let lblAzanName : UILabel = cell.contentView.viewWithTag(10) as! UILabel
            let strFileName: String = String(describing: lblAzanName.text).lowercased()
            preferences.set(strFileName, forKey: self.keyForAzan)
            preferences.synchronize()
            
            let btnAzanSelection : UIButton = cell.viewWithTag(12) as! UIButton
            btnAzanSelection.setImage(UIImage(named: "checked"), for: .normal)
            btnAzanSelection.imageEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18)
        }
        
    }
    
    func playPauseAzan(_ sender: UIButton)
    {
        
        let cells = self.tblAdhan.visibleCells
        
        for cell in cells {
            let btnPlayPause : UIButton = cell.contentView.viewWithTag(11) as! UIButton
            btnPlayPause.setTitle("Play", for: .normal)
        }
        
        
        if let cell = sender.superview?.superview as? UITableViewCell {
            let btnPlayPause : UIButton = cell.contentView.viewWithTag(11) as! UIButton
            
            if btnPlayPause.titleLabel?.text?.lowercased() == "play"{
                btnPlayPause.setTitle("Pause", for: .normal)
                
                let lblAzanName : UILabel = cell.contentView.viewWithTag(10) as! UILabel
                
                let strResourceFile: String = lblAzanName.text!
                
                if (audioPlayer.accessibilityLabel == strResourceFile) && audioPlayer.currentTime > 0 {
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
                            audioProgress.maximumValue = Float(audioPlayer.duration)
                            audioPlayer.play()
                            
                            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(SettingsViewController.updateSlider), userInfo: cell, repeats: true)
                            
                        }catch let error as NSError{
                            print(error.localizedDescription)
                        }
                    }
                    
                }
            }else{
                btnPlayPause.setTitle("Play", for: .normal)
                
                if audioPlayer.isPlaying{
                    let time : TimeInterval = audioPlayer.currentTime
                    audioPlayer.pause()
                    audioPlayer.currentTime = time
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if audioProgress.value > 0 {
            audioPlayer.stop()
        }
    }
    
    func updateSlider(_ timer: Timer){
        audioProgress.value = Float(audioPlayer.currentTime)
        
        if audioProgress.value == 0 {
            let cell = timer.userInfo as! UITableViewCell
            let btnPlayPause : UIButton = cell.contentView.viewWithTag(11) as! UIButton
            btnPlayPause.setTitle("Play", for: .normal)
        }
    }
    
    func sliderValueDidChange(sender:UISlider!)
    {
        if audioPlayer.isPlaying{
            audioPlayer.currentTime = TimeInterval(sender.value)
        }
    }
    
}
