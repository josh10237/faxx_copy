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
import MessageKit

class MainViewController: UIViewController, FirebaseManagerDelegate {
    
    // MARK: - Firebase delegate
    
    func updateMessage(_ message: MockMessage) {
        return
    }
    
    func setTypingStatus(_ otherUserId: String, _ typing: Bool) {
        let index = self.userIds.firstIndex { (item) -> Bool in
            return item.userId == otherUserId
        }
        if index != nil {
            self.userIds[index!].isTyping = typing
            self.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
        }
    }
    
    func onMessageAdded(_ message: MockMessage) {
        return
    }
    
    func onSelfStateChanged(_ state: UserContact) {
        let index = self.userIds.firstIndex { (item) -> Bool in
            return item.userId == state.userId
        }
        if index != nil {
            print("isNew: ", state.isNew)
            self.userIds[index!].isNew = state.isNew
            self.userIds[index!].time_ref = state.time_ref
            self.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
        }
    }
    
    func onUserAdded(_ user: UserContact) {
        if user.userId == self.externalID {
            self.curUser = user
        } else {
            self.firebaseManager.observeMessageThread(self.externalID, user.userId)
            let index = self.userIds.firstIndex { (item) -> Bool in
                return item.userId == user.userId
            }
            if index != nil {
                self.userIds[index!] = user
                self.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
            } else {
                self.userIds.append(user)
                let ordered = self.userIds.sorted(by: self.compareNames)
                self.userIds = ordered
                self.tableView.reloadData()
            }
        }
    }
    
    
    // MARK: - Interface Builder
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var iconView: UIButton!
    @IBOutlet weak var getMessages: UIButton!
    
    let firebaseManager = FirebaseManager()
    
    var userIds: [UserContact] = []
    var curUser: UserContact?
    var externalID: String = ""
    var userEntity: UserEntity?
    var shareURL = ""
    var myDispName = ""
    var myAvatarURL = ""
    var lastScoreUploadTime:Int = 0
    private var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firebaseManager.delegate = self
        
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        self.externalID = getExtenalId(self.userEntity?.externalID ?? "")
        myDispName = userEntity?.displayName ?? ""
        
        let d = Int(getCurrentUtcTimeInterval())
        if d > (lastScoreUploadTime + 10800){ // Plus 3 hours
            uploadScore()
            lastScoreUploadTime = d
        }
        
        if userEntity != nil {
            SCSDKBitmojiClient.fetchAvatarURL { (avatarURL: String?, error: Error?) in
                DispatchQueue.main.async {
                    var avatar = avatarURL ?? ""
                    if avatar == "" {
                        avatar = DefaultAvatarUrl
                    }
                    self.myAvatarURL = avatar
                    self.addProfileButton(withAction: #selector(self.navigateToProfile), image: UIImage.load(from: avatar)!)
                }
            }
        }
        updateUser()
        
        self.addTitle(title: "Messages")
        self.addChatButton(withAction: #selector(navigateToAbout))
        
        refresh(self)
        
    }
    
    func updateUser() {
        let info = [
            "DisplayName": self.userEntity?.displayName ?? "",
            "Avatar": self.userEntity?.avatar ?? DefaultAvatarUrl,
            "Sex": UserGender ?? "Female",
            "Age": 1000,
            "FCM_Token": FCM_Token
        ] as [String : Any]
        firebaseManager.updateUser(externalID, info)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        userIds.removeAll()
        tableView.reloadData()
        refreshControl.endRefreshing()
        
        firebaseManager.observeNewUser(self.externalID)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        
    }
   
    func compareNames(s1 :UserContact, s2: UserContact) -> Bool {
        return s1.time_ref > s2.time_ref
    }
        
    
    @objc func navigateToProfile() {
        uploadScore()
        let d = Int(getCurrentUtcTimeInterval())
        lastScoreUploadTime = d
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
    
    func uploadScore(){
        let query = Constants.refs.databaseRoot.child("UserData").child(self.externalID).queryLimited(toLast: 1000)
        _ = query.observe(.childAdded, with: { [weak self] snapshot in
            if String(snapshot.key) != "Info" {
                let theirUserId = String(snapshot.key)
                if  scoreDict[theirUserId] != nil {
                    let userScoreIncreaseFromPeriod = scoreDict[theirUserId]
                    if userScoreIncreaseFromPeriod != nil {
                        let snpsht = snapshot.value as! NSDictionary
                        let preUploadUserScore = snpsht.value(forKey: "score") as? Int
                        if preUploadUserScore != nil {
                            Constants.refs.databaseRoot.child("UserData").child(self!.externalID).child(theirUserId).child("score").setValue(preUploadUserScore!  + userScoreIncreaseFromPeriod!)
                            scoreDict = [:]
                        }
                    }
                }
            }
        })
    }
    
    func goToChat(otherUserId: String, otherUserPushToken: String, otherUserAvatar: String, otherUserDisplayName: String, otherAnon: Bool) {
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
        newViewController.userEntity = userEntity
        newViewController.otherUserID = otherUserId
        newViewController.externalID = self.externalID
        newViewController.otherUserPushToken = otherUserPushToken
        newViewController.areTheyAnon = otherAnon //if the other userid starts with anon delimiter than true else false
        newViewController.otherUserAvatar = otherUserAvatar
        newViewController.otherUserDisplayName = otherUserDisplayName
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
    @IBAction func getMessages(_ sender: Any) {
        getURL()
    }
    
    func postToSnap(){
        let snap = SCSDKNoSnapContent()
        snap.sticker = SCSDKSnapSticker(stickerImage: #imageLiteral(resourceName: "swipeUp"))
        snap.attachmentUrl = (self.shareURL)
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
        lp.addControlParam("fcm_token", withValue: self.curUser?.fcm_token ?? "")
        lp.addControlParam("avatar", withValue: self.userEntity?.avatar ?? DefaultAvatarUrl)
        lp.addControlParam("displayName", withValue: userEntity?.displayName ?? "Annoymous")
        lp.addControlParam("gender", withValue: UserGender ?? "Other")
        lp.addControlParam("random", withValue: UUID.init().uuidString)
        
        buo.getShortUrl(with: lp) { url, error in
            self.shareURL = url ?? ""
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
        
        let userInfo = userIds[indexPath.row]
        if userInfo.isNew {
            cell.newMessageDot.image = UIImage(named: "unread_message")
            cell.nameLabel.textColor = UIColor.black
        } else {
            cell.newMessageDot.image = nil
            cell.nameLabel.textColor = UIColor.darkGray
        }
      
        if userInfo.isTyping {
            cell.nameArea.isHidden = true
            
            cell.typingArea.isHidden = false
            cell.typingNameLabel.text = "\(userInfo.displayName) is typing"
            cell.typingImage.showAnimatingDotsInImageView()
        } else {
            cell.nameArea.isHidden = false
            cell.nameLabel.text = userInfo.displayName
            
            cell.typingArea.isHidden = true
        }
        
        cell.profileImageView.load(from: userInfo.avatar)
        let d = getCurrentUtcTimeInterval()
        let t = userInfo.time_ref
        let final = d - t
        if t == 1000000000 {
            cell.timeLabel.text = "Long ago"
        } else if final / 604800 > 1 {
            cell.timeLabel.text = String(Int(final / 604800)) + "w"
        } else if final / 86400 > 1 {
            cell.timeLabel.text = String(Int(final / 86400)) + "d"
        } else if final / 3600 > 1 {
            cell.timeLabel.text = String(Int(final / 3600)) + "h"
        } else if final / 60 > 1 {
            cell.timeLabel.text = String(Int(final / 60)) + "m"
        } else if final > 1 {
            cell.timeLabel.text = String(Int(final)) + "s"
        } else {
            cell.timeLabel.text = "Long ago"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if userIds[indexPath.row].isNew {
            firebaseManager.setNewUserContact(externalID, userIds[indexPath.row].userId, false)
        }
        let otherUser = userIds[indexPath.row]
        self.goToChat(otherUserId: otherUser.userId, otherUserPushToken: otherUser.fcm_token, otherUserAvatar: otherUser.avatar, otherUserDisplayName: otherUser.displayName, otherAnon: otherUser.amIAnon)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let userDataRef = Constants.refs.databaseRoot.child("UserData").child(self.userIds[indexPath.row].userId)
            let messageDataRef = Constants.refs.databaseRoot.child("messageData").child(self.userIds[indexPath.row].userId)
            userIds.remove(at: indexPath.row)
            userDataRef.removeValue()
            messageDataRef.removeValue()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
}
