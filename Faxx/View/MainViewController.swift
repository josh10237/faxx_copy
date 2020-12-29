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
import SwiftyJSON
import MBProgressHUD

class MainViewController: UIViewController {
    
    
    // MARK: - Interface Builder
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var iconView: UIButton!
    @IBOutlet weak var getMessages: UIButton!
    
    let firebaseManager = FirebaseManager()
    var contactList: [ContactModel] = []
    var realContactList: [ContactModel] = []
    var externalID: String = ""
    var userEntity: UserEntity?
    var shareURL = ""
    var myDispName = ""
    var myAvatarURL = ""
    var lastScoreUploadTime:Int = 0
    private var refreshControl = UIRefreshControl()
    
    var socketIOManager = SocketIOManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: #selector(self.loadContacts), for: .valueChanged)
        tableView.addSubview(refreshControl)
        self.externalID = getExtenalId(self.userEntity?.externalID ?? "")
        myDispName = userEntity?.displayName ?? ""
        
        let d = Int(getCurrentUtcTimeInterval())
        if d > (lastScoreUploadTime + 10800){ // Plus 3 hours
            uploadScore()
            lastScoreUploadTime = d
        }
        
        if CurrentUser != nil {
            self.myAvatarURL = CurrentUser!.avatar
            self.addProfileButton(withAction: #selector(self.navigateToProfile), image: UIImage.load(from: self.myAvatarURL) ?? #imageLiteral(resourceName: "Nathan-Tannar"))
        }
        
        self.addTitle(title: "Messages")
        self.addChatButton(withAction: #selector(navigateToAbout))
        
        loadContacts()
        
        socketIOManager.establishConnection(user_id: CurrentUser?.id ?? 0)
        socketIOManager.delegate = self
    }
    
    @objc func loadContacts() {
        if let curUser = CurrentUser {
            let params = [
                "u_id": curUser.id
            ] as [String : Any]
            
            if !NetworkManager.shared.isConnectedNetwork() {
                return
            }
            
            guard let url = URL(string: NetworkManager.shared.AllContacts) else {
                return
            }
           
            NetworkManager.shared.postRequest(url: url, headers: nil, params: params) { (response) in
                if self.parseResponse(response: response) {
                    let contacts = response["contacts"].arrayValue
                    var tmp_arr: [ContactModel] = []
                    contacts.forEach { (contact) in
                        let tmp = ContactModel(contact, curUser)
                        tmp_arr.append(tmp)
                    }
                    self.contactList = tmp_arr
                    self.loadContactTable()
                } else {
                    let message = response["err_msg"].stringValue
                    self.showToastMessage(message: message)
                }
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func loadContactTable() {
        realContactList = contactList.filter({ (contact) -> Bool in
            return contact.last_msg != ""
        })
        self.tableView.reloadData()
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.view.endEditing(true)
        
//        firebaseManager.observeNewUser(self.externalID)
        current_chat_thread_id = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
    
    func goToChat(_ contact: ContactModel) {
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
        newViewController.userEntity = userEntity
        newViewController.currentUser = CurrentUser
        newViewController.contact = contact
        
//        newViewController.otherUserID = otherUserId
//        newViewController.externalID = self.externalID
//        newViewController.otherUserPushToken = otherUserPushToken
//        newViewController.areTheyAnon = otherAnon //if the other userid starts with anon delimiter than true else false
//        newViewController.otherUserAvatar = otherUserAvatar
//        newViewController.otherUserDisplayName = otherUserDisplayName
        self.navigationController?.pushViewController(newViewController, animated: true)
//        newViewController.modalPresentationStyle = .fullScreen
//        self.present(newViewController, animated: true, completion: nil)
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
        
        let anonUsers = self.contactList.filter { (item) -> Bool in
            return item.amIAnon
        }
        anonUsers.forEach { (user) in
            let token = user.t_fcm_token
            let data = [
                "senderId": CurrentUser?.id ?? 0,
                "isAnon": false
            ] as [String : Any]
            self.firebaseManager.sendPushNotification(token, String(format: GetMessagesFormat, CurrentUser?.display_name ?? ""), "", data)
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
//        lp.addControlParam("$ios_url", withValue: "https://faxxapp.page.link/snapchat")
        lp.addControlParam("$ios_url", withValue: "joshbenson://faxx")
//        lp.addControlParam("$fallback_url", withValue: "https://www.snapchat.com/")
        lp.addControlParam("$ipad_url", withValue: "https://www.snapchat.com/")
        lp.addControlParam("$android_url", withValue: "https://www.snapchat.com/")
        lp.addControlParam("$match_duration", withValue: "2000")
        lp.addControlParam("posterId", withValue: "\(CurrentUser?.id ?? 0)")
        
        buo.getShortUrl(with: lp) { url, error in
            self.shareURL = url ?? ""
            self.postToSnap()
        }
        
    }
    
    var current_chat_thread_id = 0
    
}

//MARK:- TableView Data Source And Delegate Methods

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return realContactList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath) as! MessageTableViewCell
        let contact = realContactList[indexPath.row]
        if contact.last_msg_status == "unread" {
            cell.newMessageDot.image = UIImage(named: "unread_message")
            cell.nameLabel.textColor = UIColor.black
        } else {
            cell.newMessageDot.image = nil
            cell.nameLabel.textColor = UIColor.darkGray
        }

        var display_name = contact.t_display_name
        var avatar = contact.t_avatar
        if contact.areTheyAnon {
            display_name = contact.t_anon_display_name
            avatar = contact.t_anon_avatar
        }
        
        if contact.isTyping {
            cell.nameArea.isHidden = true

            cell.typingArea.isHidden = false
            
            cell.typingNameLabel.text = "\(display_name) is typing"
            cell.typingImage.showAnimatingDotsInImageView()
        } else {
            cell.nameArea.isHidden = false
            cell.nameLabel.text = display_name

            cell.typingArea.isHidden = true
        }
        
        if contact.amIAnon {
            cell.lbl_anonymous.isHidden = true
            cell.lbl_anonymous_2.isHidden = true
        } else {
            cell.lbl_anonymous.isHidden = false
            cell.lbl_anonymous_2.isHidden = false
        }
        
        cell.profileImageView.load(from: avatar)
        let d = getCurrentUtcTimeInterval()
        let t = contact.last_msg_timestamp
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
            cell.timeLabel.text = "Just now"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let contact = realContactList[indexPath.row]
        if self.current_chat_thread_id != contact.id {
            self.goToChat(contact)
            self.current_chat_thread_id = contact.id
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete contact
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
}

extension MainViewController: SocketIOManagerDelegate {
    func messageReceived(result: JSON) {
        if result.arrayValue.count > 0 {
            let message =  result.arrayValue[0]
            if let chatView = self.navigationController?.viewControllers.last as? ChatViewController {
                chatView.onMessageAdded(message)
            }
        }
    }
    
    func lastMessageUpdated(result: JSON) {
        if result.arrayValue.count > 0 {
            let message =  result.arrayValue[0]
            let c_id = message["c_id"].intValue
            
            let index = self.contactList.firstIndex { (contact) -> Bool in
                return contact.id == c_id
            }
            if index != nil {
                let contact = self.contactList[index!]
                contact.last_msg = message["msg_content"].stringValue
                contact.last_msg_type = message["msg_type"].stringValue
                contact.last_msg_status = message["msg_status"].stringValue
                contact.last_msg_timestamp = message["add_time"].doubleValue
                
                let index_1 = self.realContactList.firstIndex { (contact) -> Bool in
                    return contact.id == c_id
                }
                if index_1 != nil {
                    self.realContactList[index_1!] = contact
                    self.tableView.reloadRows(at: [IndexPath(row: index_1!, section: 0)], with: .automatic)
                } else {
                    self.loadContactTable()
                }
            }
        }
    }
    
    func readMessage(result: JSON) {
        if result.arrayValue.count > 0 {
            let message =  result.arrayValue[0]
            if let chatView = self.navigationController?.viewControllers.last as? ChatViewController {
                chatView.updateMessage(message)
            }
        }
    }
    
    func readAllMessage(result: JSON) {
        if result.arrayValue.count > 0 {
            let message =  result.arrayValue[0]
            if let chatView = self.navigationController?.viewControllers.last as? ChatViewController {
                chatView.updateMessage(message)
            }
        }
    }
    
    func contactCreated(result: JSON) {
        if result.arrayValue.count > 0 {
            let tmp =  result.arrayValue[0]
            if let curUser = CurrentUser {
                let contact = ContactModel(tmp, curUser)
                let c_id = contact.id
                let index = self.contactList.firstIndex { (contact) -> Bool in
                    return contact.id == c_id
                }
                if index == nil {
                    self.contactList.insert(contact, at: 0)
                }
            }
            
        }
    }
    
    func userTyping(result: JSON) {
        if result.arrayValue.count > 0 {
            let item = result.arrayValue[0]
            let c_id = item["c_id"].intValue
            let typing = item["typing"].intValue == 0 ? false : true
            let index = self.realContactList.firstIndex { (contact) -> Bool in
                return contact.id == c_id
            }
            if index != nil {
                let contact = self.realContactList[index!]
                contact.isTyping = typing
                self.realContactList[index!] = contact
                self.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .automatic)
            }
            
            if let chatView = self.navigationController?.viewControllers.last as? ChatViewController {
                chatView.setTypingStatus(typing: typing)
            }
        }
    }
    
}

