//
//  UIViewController+Extensions.swift
//  SnapClient
//
//  Created by Josh Benson on 7/31/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func addTitle(title:String){
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byCharWrapping
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.text = title
        titleLabel.sizeToFit()
        titleLabel.font = UIFont.systemFont(ofSize: 24.0)
        self.navigationItem.titleView = titleLabel
    }
    
    func addProfileButton(withAction action:Selector, image: UIImage){
        let profileButton: UIButton = UIButton(type: UIButton.ButtonType.custom)
        profileButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        profileButton.imageView?.contentMode = .scaleAspectFit
        profileButton.setImage(image, for: .normal)
        profileButton.addTarget(self, action: action, for: .touchUpInside)
        let profileBarButton = UIBarButtonItem(customView: profileButton)
        let width = profileBarButton.customView?.widthAnchor.constraint(equalToConstant: 40.0)
        width?.isActive = true
        let height = profileBarButton.customView?.heightAnchor.constraint(equalToConstant: 40.0)
        height?.isActive = true
        
        self.navigationItem.rightBarButtonItem = profileBarButton
    }
    
    func addChatButton(withAction action:Selector){
        let chatButton: UIButton = UIButton(type: UIButton.ButtonType.custom)
        chatButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        chatButton.imageView?.contentMode = .scaleAspectFit
        chatButton.setImage(UIImage(named: "faxx_ART_MAIN1024"), for: .normal)
        chatButton.addTarget(self, action: action, for: .touchUpInside)
        let chatBarButton = UIBarButtonItem(customView: chatButton)
        let width = chatBarButton.customView?.widthAnchor.constraint(equalToConstant: 40.0)
        width?.isActive = true
        let height = chatBarButton.customView?.heightAnchor.constraint(equalToConstant: 40.0)
        height?.isActive = true
        
        self.navigationItem.leftBarButtonItem = chatBarButton
    }
}
