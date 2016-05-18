//
//  ParkingList_TableViewCell.swift
//  ParkingTaipei
//
//  Created by Ka Ho on 15/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import UIKit

class ParkingList_TableViewCell: UITableViewCell {
    
    @IBOutlet weak var name, distance: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        name.adjustsFontSizeToFitWidth = true
        distance.adjustsFontSizeToFitWidth = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
