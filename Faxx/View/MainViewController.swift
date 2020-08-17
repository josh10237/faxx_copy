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
    
    var userIds: [[String: String]] = [[:]]
    var externalID:String = ""
    var userEntity: UserEntity?
    var URL = ""
    var dispSetYet = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("LOAD MAIN VC")
        print(userEntity)
        self.addTitle(title: "Messages")
        self.addChatButton(withAction: #selector(navigateToAbout))
        
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
        
        if userEntity != nil {
            SCSDKBitmojiClient.fetchAvatarURL { (avatarURL: String?, error: Error?) in
                DispatchQueue.main.async {
                    if let avatarURL = avatarURL {
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
        DispatchQueue.main.async {
            let qq = Constants.refs.databaseRoot.child(self.externalID).child("Info").queryLimited(toLast: 1)
            _ = qq.observe(.childAdded, with: { [weak self] snapshot in
                let nm = String(snapshot.key)
                print(nm)
                self!.dispSetYet = true
                print("DISPSETYET")
                print(self!.dispSetYet)
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                if !self.dispSetYet{
                    print("Reset")
                    let ref = Constants.refs.databaseRoot.child(self.externalID).child("Info")
                    let content = [self.userEntity?.displayName: self.userEntity?.avatar]
                    ref.setValue(content)
                    self.dispSetYet = true
                }
            })
        }
        
        let query = Constants.refs.databaseRoot.child(self.externalID).queryLimited(toLast: 1000)
        _ = query.observe(.childAdded, with: { [weak self] snapshot in
            
            let data = String(snapshot.key)
            if data != "Info"{
                let query1 = Constants.refs.databaseRoot.child(data).child("Info").queryLimited(toLast: 1)
                _ = query1.observe(.childAdded, with: { [weak self] snapshot in
                    let av = snapshot.value as! String
                    let nm = String(snapshot.key)
                    let query2 = Constants.refs.databaseRoot.child(self!.externalID).child(data).queryLimited(toLast: 1)
                    _ = query2.observe(.childAdded, with: { [weak self] snapshot in
                        let data1 = snapshot.value as? [String: Any]
                        let time = data1!["time"]
                        let senderId = data1!["sender_id"]
                        let text = data1!["text"]
                        print(time)
                        let t = Int((time as! NSString).intValue)
                        let d = Int(Date().timeIntervalSinceReferenceDate)
                        let timeSince = d - t
//                        self!.userIds.append(["userID": "\(data)", "displayName": nm, "avatar": av, "time_ref": "\(time)"])
//                        let ordered = self!.userIds.sorted(by: self!.compareNames)
//                        self?.userIds = ordered
//                        self?.tableView.reloadData()
                        if t != 1000000000
                        {
                            if timeSince > 60 {//1209600 {
                                print("hi")
                                let ref = Constants.refs.databaseRoot.child(self!.externalID).child(data)
                                let refOther = Constants.refs.databaseRoot.child(data).child(self!.externalID)
                                ref.setValue("")
                                refOther.setValue("")
                                let content = ["sender_id": senderId, "text": text, "time": "1000000000"]
                                ref.childByAutoId().setValue(content)
                                refOther.childByAutoId().setValue(content)
                                self?.tableView.reloadData()
                            }
                        }
                        //TODO: Add thing to block duplicates cuz there is weird bug when user updates to long ago while still in the app
                        self!.userIds.append(["userID": "\(data)", "displayName": nm, "avatar": av, "time_ref": "\(time)"])
                        let ordered = self!.userIds.sorted(by: self!.compareNames)
                        self?.userIds = ordered
                        self?.tableView.reloadData()
                        })
                })
            }
        })
        
    }
    
    func compareNames(s1:[String : String], s2:[String : String]) -> Bool {
        let v1 = s1["time_ref"]
        let v2 = s2["time_ref"]
        let vv1 = "\(v1)"
        let vv2 = "\(v2)"
        return vv1 > vv2
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
    
    
    
    func goToChat(otherUserId: String, otherUserDisplayName: String){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.userEntity = userEntity
        newViewController.otherUserID = otherUserId
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
        
        cell.nameLabel.text = userIds[indexPath.row]["displayName"]
        cell.profileImageView.load(from: userIds[indexPath.row]["avatar"] ?? "")
        let d = Int(Date().timeIntervalSinceReferenceDate)
        let ref1 = Constants.refs.databaseRoot.child(self.externalID)
        let query = ref1.child(userIds[indexPath.row]["userID"]!).queryLimited(toLast: 1)
        _ = query.observe(.childAdded, with: { [weak self] snapshot in

            let data = snapshot.value as? [String: Any]
            let time = data!["time"]
            let t = Int((time as! NSString).intValue)
            let final = d - t
            print("eyy")
            print (final)
            print(time)
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
        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.goToChat(otherUserId: userIds[indexPath.row]["userID"]!, otherUserDisplayName: userIds[indexPath.row]["displayName"]!)
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print(userIds)
            print(indexPath.row)
            print(self.userIds[indexPath.row])
            print(self.userIds[indexPath.row]["userID"] as Any)
            let ref = Constants.refs.databaseRoot.child(self.externalID).child(self.userIds[indexPath.row]["userID"]!)
            userIds.remove(at: indexPath.row)
            ref.removeValue()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
}
