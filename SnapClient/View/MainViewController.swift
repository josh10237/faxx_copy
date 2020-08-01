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
    
    //MARK: Interface Builder
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var iconView: UIButton!
    @IBOutlet weak var getMessages: UIButton!
    
    var userIds: [String] = []
    var externalID:String = ""
    var userEntity: UserEntity?
    var URL = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitle(title: "Messages")
        self.addChatButton(withAction: #selector(navigateToAbout))
        
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6))
        
        if userEntity != nil {
            SCSDKBitmojiClient.fetchAvatarURL { (avatarURL: String?, error: Error?) in
                DispatchQueue.main.async {
                    if let avatarURL = avatarURL {
                        self.addProfileButton(withAction: #selector(self.navigateToProfile), image: UIImage.load(from: avatarURL)!)
                    }
                }
            }
        }
        
        let query = Constants.refs.databaseRoot.child(self.externalID).queryLimited(toLast: 10)
        _ = query.observe(.childAdded, with: { [weak self] snapshot in

            let data = snapshot.key
            self!.userIds.append(data)
            self?.tableView.reloadData()
            //self!.addToStack(disply: data)
        })
        
        //self.makeScrollable()
    }
    
    @objc func navigateToProfile() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "profile") as! ProfileViewController
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.userEntity = userEntity
        
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
    @objc func navigateToAbout() {
        print("About Page")
    }
    
    
    
    func goToChat(otherUserId: String){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.userEntity = userEntity
        newViewController.otherUserID = otherUserId
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
    @IBAction func getMessages(_ sender: Any) {
        getURL()
    }
    
    
    func postToSnap(){
        let snap = SCSDKNoSnapContent()
        snap.sticker = SCSDKSnapSticker(stickerImage: #imageLiteral(resourceName: "SwipeUp"))
        snap.attachmentUrl = (self.URL)
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

//MARK:- TableView Data Source And Delegate Methods
extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userIds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath) as! MessageTableViewCell
        cell.nameLabel.text = userIds[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.goToChat(otherUserId: userIds[indexPath.row])
    }
    
    
}
