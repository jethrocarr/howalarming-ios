//
//  AlarmEventTableViewCell.swift
//  howalarming
//
//  Created by Jethro Carr on 25/05/16.
//  Copyright © 2016 Jethro Carr. All rights reserved.
//

import UIKit

class AlarmEventTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
