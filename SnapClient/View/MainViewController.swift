//
//  MainViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/16/20.
//  Copyright © 2020 Kboy. All rights reserved.
//

import Foundation
import UIKit
import SCSDKLoginKit
import SCSDKBitmojiKit


class MainViewController: UIViewController {
    var userEntity: UserEntity?
    @IBOutlet weak var iconView: UIButton!
    @IBOutlet weak var getMessages: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        let barLayer = CALayer()
        let screenSize: CGRect = UIScreen.main.bounds
        let rectFrame: CGRect = CGRect(x:CGFloat(0), y:CGFloat(0), width:CGFloat(screenSize.width), height:CGFloat(100))
        barLayer.frame = rectFrame
        barLayer.backgroundColor = FaxxPink.cgColor
        view.layer.insertSublayer(barLayer, at: 0)
        SCSDKBitmojiClient.fetchAvatarURL { (avatarURL: String?, error: Error?) in
            DispatchQueue.main.async {
                if let avatarURL = avatarURL {
                    self.iconView.setImage(UIImage.load(from: avatarURL), for: .normal)
                    self.iconView.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
                    self.iconView.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
                    
                }
            }
        }
    }
    @available(iOS 13.0, *)
    private func goToChat(){
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(identifier: "chat") as!ChatViewController
            newViewController.modalPresentationStyle = .fullScreen
            newViewController.userEntity = userEntity
            self.present(newViewController, animated: true, completion: nil)
        }
    
    @available(iOS 13.0, *)
    private func goToProfile(){
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(identifier: "profile") as!ProfileViewController
            newViewController.modalPresentationStyle = .fullScreen
            newViewController.userEntity = userEntity
            self.present(newViewController, animated: true, completion: nil)
        }

    @available(iOS 13.0, *)
    @IBAction func goButtonTapped(_ sender: Any) {
            goToChat()
        }
    
    @available(iOS 13.0, *)
    @IBAction func profileButtonTapped(_ sender: Any) {
            goToProfile()
        }

    }
    
