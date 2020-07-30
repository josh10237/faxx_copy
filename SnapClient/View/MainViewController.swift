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
import SCSDKCreativeKit
import Branch

class MainViewController: UIViewController {
    var userEntity: UserEntity?
    var URL = ""
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
        if userEntity != nil {
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
    }
    @available(iOS 13.0, *)
    func goToChat(){
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(identifier: "chat") as!ChatViewController
            newViewController.modalPresentationStyle = .fullScreen
            newViewController.userEntity = userEntity
            newViewController.otherUserID = "4fnuew8efwef8wn"
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
    
    @IBAction func getMessages(_ sender: Any) {
        getURL()
    }
    
    
    func postToSnap(){
        print("URL")
        print(self.URL)
        let snap = SCSDKNoSnapContent()
        snap.sticker = SCSDKSnapSticker(stickerImage: #imageLiteral(resourceName: "SwipeUp"))
        snap.attachmentUrl = (self.URL)
        print("FINAL")
        print(snap.attachmentUrl)
        let api = SCSDKSnapAPI(content: snap)
        api.startSnapping { error in
                    
            if let error = error {
                print(error.localizedDescription)
            } else {
                // success
            
            }
        }

    }
    
    func getURL() {
        Branch.getInstance().setIdentity(String((userEntity?.externalID)!.dropFirst(6)))
        let buo = BranchUniversalObject.init(canonicalIdentifier: "content/12345")
        buo.title = "Swipe Up"
        buo.publiclyIndex = true
        buo.locallyIndex = true
        let lp: BranchLinkProperties = BranchLinkProperties()

        lp.addControlParam("$desktop_url", withValue: "https://www.snapchat.com/")
        lp.addControlParam("$ios_url", withValue: "joshbenson://faxx")
        lp.addControlParam("$fallback_url", withValue: "https://www.snapchat.com/")
        lp.addControlParam("$ipad_url", withValue: "https://www.snapchat.com/")
        lp.addControlParam("$android_url", withValue: "https://www.snapchat.com/")
        lp.addControlParam("$match_duration", withValue: "2000")

        lp.addControlParam("user", withValue: String((userEntity?.externalID)!.dropFirst(6)))
        lp.addControlParam("random", withValue: UUID.init().uuidString)
        
        buo.getShortUrl(with: lp) { url, error in
            print("IN RET")
            print(url ?? "")
            self.URL = url ?? ""
            self.postToSnap()
        }

    }

    }
    
