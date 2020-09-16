//
//  MainViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/16/20.
//  Copyright © 2020 FAXX. All rights reserved.
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
    
    
    var userIds: [[String: Any]] = [[:]]
    var externalID:String = ""
    var userEntity: UserEntity?
    var URL = ""
    var myDispName = ""
    var myAvatarURL = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitle(title: "Messages")
        self.addChatButton(withAction: #selector(navigateToAbout))
        
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
        
        if userEntity != nil {
            SCSDKBitmojiClient.fetchAvatarURL { (avatarURL: String?, error: Error?) in
                DispatchQueue.main.async {
                    if let avatarURL = avatarURL {
                        self.myAvatarURL = avatarURL
                        self.addProfileButton(withAction: #selector(self.navigateToProfile), image: UIImage.load(from: avatarURL)!)
                    }
                }
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        userIds.removeAll()
        tableView.reloadData()
//        DispatchQueue.main.async {
//            let qq = Constants.refs.databaseRoot.child("userData").child(self.externalID).child("Info").queryLimited(toLast: 1)
//            _ = qq.observe(.childAdded, with: { [weak self] snapshot in
//                let nm = String(snapshot.key)
//                self!.dispNotSetYet = false
//            })
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//                if self.dispNotSetYet{
//                    print("Reset")
//                    let ref = Constants.refs.databaseRoot.child(self.externalID).child("Info")
//                    let content = [self.userEntity?.displayName: self.userEntity?.avatar]
//                    ref.setValue(content)
//                    self.dispNotSetYet = false
//                }
//            })
//        }
        //Query all convos under your user id
        let query = Constants.refs.databaseRoot.child("UserData").child(self.externalID).queryLimited(toLast: 100)
        _ = query.observe(.childAdded, with: { [weak self] snapshot in
            let theirID = String(snapshot.key)
            //if data (each other user id) is not info
            if theirID == "Info"{
                let snpsht = snapshot.value as! NSDictionary
                self!.myDispName = snpsht.allKeys.first as! String
            } else if theirID != "Sex" {
                let snpsht = snapshot.value as! NSDictionary
                let theirInfo = snpsht["Info"] as! NSDictionary
                let displayName = theirInfo.allKeys.first
                let avatarURL = theirInfo.allValues.first
                let time = snpsht.value(forKey: "time")
                let isNew = snpsht.value(forKey: "isNew")
                self!.userIds.append(["userID": "\(theirID)", "displayName": displayName, "avatar": avatarURL, "time_ref": time, "isNew": isNew, "amIAnon": false])
                let ordered = self!.userIds.sorted(by: self!.compareNames)
                self?.userIds = ordered
                self?.tableView.reloadData()
            }
        })
        
        let queryAnon = Constants.refs.databaseRoot.child("UserData").child("ZAAAAA3AAAAAZ" + self.externalID).queryLimited(toLast: 100)
        _ = queryAnon.observe(.childAdded, with: { [weak self] snapshot in
            let theirID = String(snapshot.key)
            //if data (each other user id) is not info
            if theirID == "Info"{
                let snpsht = snapshot.value as! NSDictionary
                self!.myDispName = snpsht.allKeys.first as! String
            } else if theirID != "Sex" {
                let snpsht = snapshot.value as! NSDictionary
                let theirInfo = snpsht["Info"] as! NSDictionary
                let displayName = theirInfo.allKeys.first
                let avatarURL = theirInfo.allValues.first
                let time = snpsht.value(forKey: "time")
                let isNew = snpsht.value(forKey: "isNew")
                self!.userIds.append(["userID": "\(theirID)", "displayName": displayName, "avatar": avatarURL, "time_ref": time, "isNew": isNew, "amIAnon": true])
                let ordered = self!.userIds.sorted(by: self!.compareNames)
                self?.userIds = ordered
                self?.tableView.reloadData()
            }
        })
    }
    
    func compareNames(s1:[String : Any], s2:[String : Any]) -> Bool {
        let v1 = s1["time_ref"] as! Int
        let v2 = s2["time_ref"] as! Int
        return v1 > v2
    }
        
    
    @objc func navigateToProfile() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "profile") as! ProfileViewController
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.myDispName = myDispName
        newViewController.avatarURL = myAvatarURL
        newViewController.userEntity = userEntity
        
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
    @objc func navigateToAbout() {
        print("About Page")
    }
    
    
    
    func goToChat(otherUserId: String, otherUserDisplayName: String, amIAnon: Bool){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.userEntity = userEntity
        newViewController.otherUserID = otherUserId
        newViewController.externalID = self.externalID
        newViewController.amIAnon = amIAnon
        newViewController.areTheyAnon = otherUserId.hasPrefix("ZAAAAA3AAAAAZ") //if the other userid starts with anon delimiter than true else false
        newViewController.otherUserDisplayName = otherUserDisplayName
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
    @IBAction func getMessages(_ sender: Any) {
        getURL()
    }
    
    
    func postToSnap(){
        let snap = SCSDKNoSnapContent()
        snap.sticker = SCSDKSnapSticker(stickerImage: #imageLiteral(resourceName: "swipeUp"))
        snap.attachmentUrl = (self.URL)
        let api = SCSDKSnapAPI(content: snap)
        api.startSnapping { error in
            
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
    }
    
    func getURL() {
        Branch.getInstance().setIdentity(externalID)
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
        lp.addControlParam("user", withValue: String((userEntity?.externalID)!.dropFirst(6)).replacingOccurrences(of: "/", with: ""))
        lp.addControlParam("random", withValue: UUID.init().uuidString)
        
        buo.getShortUrl(with: lp) { url, error in
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
        if userIds[indexPath.row]["isNew"] as! Int == 1{
            cell.newMessageDot.image = UIImage(named: "unread_message")
            cell.nameLabel.textColor = UIColor.black
        } else {
            cell.newMessageDot.image = nil
            cell.nameLabel.textColor = UIColor.darkGray
        }
//        if userIds[indexPath.row]["isAnon"] as! Int == 1{
//            cell.anonLabel.isHidden = false
//        } else {
//            cell.anonLabel.isHidden = true
//        }
        cell.nameLabel.text = userIds[indexPath.row]["displayName"] as! String
        cell.profileImageView.load(from: userIds[indexPath.row]["avatar"] as! String)
        let d = Int(Date().timeIntervalSinceReferenceDate)
        print(userIds)
        var t = userIds[indexPath.row]["time_ref"] as! Int
        let final = d - t
        if t == 1000000000 {
            cell.timeLabel.text = "Long ago"
        }
        else if final / 604800 > 0 {
            cell.timeLabel.text = String(final / 604800) + "w"
        }else if final / 86400 > 0 {
            cell.timeLabel.text = String(final / 86400) + "d"
        } else if final / 3600 > 0{
            cell.timeLabel.text = String(final / 3600) + "h"
        } else if final / 60 > 0{
            cell.timeLabel.text = String(final / 60) + "m"
        } else {
            cell.timeLabel.text = String(final) + "s"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if userIds[indexPath.row]["isNew"] as! Int == 1{
            let userDataRefMe = Constants.refs.databaseRoot.child("UserData").child(self.externalID).child(userIds[indexPath.row]["userID"] as! String)
            userDataRefMe.child("isNew").setValue(false)
        }
        self.goToChat(otherUserId: userIds[indexPath.row]["userID"] as! String, otherUserDisplayName: userIds[indexPath.row]["displayName"] as! String, amIAnon: userIds[indexPath.row]["amIAnon"] as! Bool)
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let userDataRef = Constants.refs.databaseRoot.child("UserData").child(self.externalID).child(self.userIds[indexPath.row]["userID"] as! String)
            let messageDataRef = Constants.refs.databaseRoot.child("messageData").child(self.externalID).child(self.userIds[indexPath.row]["userID"] as! String)
            userIds.remove(at: indexPath.row)
            userDataRef.removeValue()
            messageDataRef.removeValue()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
}
