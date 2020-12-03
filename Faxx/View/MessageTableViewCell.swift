//
//  MessageTableViewCell.swift
//  SnapClient
//
//  Created by Josh Benson on 7/31/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    
    //MARK:- Interface Builder
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameArea: UIStackView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var newMessageDot: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var typingArea: UIView!
    @IBOutlet weak var typingNameLabel: UILabel!
    @IBOutlet weak var typingImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
