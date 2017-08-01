//
//  NamazCell.swift
//  NamazPro
//
//  Created by al-insan on 03/05/17.
//  Copyright © 2017 al-insan. All rights reserved.
//

import UIKit

class NamazCell: UITableViewCell {

    @IBOutlet weak var lblPrayerName: UILabel!
    @IBOutlet weak var lblPrayerTime: UILabel!
    @IBOutlet weak var imgAlarmType: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
