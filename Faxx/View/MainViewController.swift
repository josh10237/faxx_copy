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
    
    // MARK: - Socket Handler
    func setTyping(_ item: JSON) {
        let c_id = item["c_id"].intValue
        let typing = item["typing"].intValue == 0 ? false : true
        
        let index = realContactList.firstIndex { (contact) -> Bool in
            return contact.id == c_id
        }
        if index != nil {
            let contact = realContactList[index!]
            if !(contact.isTyping && typing) {
                contact.isTyping = typing
                realContactList[index!] = contact
                tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
                
                if typing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        let contact = self.realContactList[index!]
                        contact.isTyping = false
                        self.realContactList[index!] = contact
                        self.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
                    }
                }
            }
        }
    }
    
    var socketIOManager: SocketIOManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDelegate()?.mainView = self
        self.socketIOManager = self.appDelegate()?.socketIOManager ?? SocketIOManager.shared
        
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
            
            self.appDelegate()?.connectSocket(CurrentUser?.id ?? 0)
        }
        
        self.addTitle(title: "Messages")
        self.addChatButton(withAction: #selector(navigateToAbout))
        
        loadContacts()
        
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
                    self.contactList = []
                    self.loadContactTable()
                }
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func loadContactTable() {
        realContactList = contactList.filter({ (contact) -> Bool in
            return contact.last_msg != "" && contact.d_start_msg_id >= contact.d_last_msg_id
        })
        sortContact()
        self.tableView.reloadData()
    }
    
    func sortContact() {
        realContactList = realContactList.sorted(by: { (tmp1, tmp2) -> Bool in
            return tmp1.last_msg_timestamp > tmp2.last_msg_timestamp
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.view.endEditing(true)
        
//        firebaseManager.observeNewUser(self.externalID)
        current_chat_thread_id = 0
    }
    
    var isFromNotification = false
    var chatView: ChatViewController?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFromNotification && chatView != nil {
            self.navigationController?.pushViewController(chatView!, animated: true)
            
            isFromNotification = false
            chatView = nil
        }
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
        let deepLinkUrl = String(format: NetworkManager.shared.DeepLinkUrl, CurrentUser?.id ?? 0)
//        lp.addControlParam("$desktop_url", withValue: "https://www.snapchat.com/")
//        lp.addControlParam("$ios_url", withValue: "https://faxxapp.page.link/snapchat")
        lp.addControlParam("$ios_url", withValue: deepLinkUrl)
//        lp.addControlParam("$fallback_url", withValue: "https://www.snapchat.com/")
//        lp.addControlParam("$ipad_url", withValue: "https://www.snapchat.com/")
//        lp.addControlParam("$android_url", withValue: "https://www.snapchat.com/")
//        lp.addControlParam("$match_duration", withValue: "2000")
//        lp.addControlParam("posterId", withValue: "\(CurrentUser?.id ?? 0)")
        
        buo.getShortUrl(with: lp) { url, error in
            self.shareURL = url ?? ""
            self.postToSnap()
        }
    }
    
    func deleteContact(_ contact: ContactModel) {
        let params = [
            "c_id": contact.id,
            "u_id": contact.f_id
        ] as [String : Any]
        
        if !NetworkManager.shared.isConnectedNetwork() {
            return
        }
        
        guard let url = URL(string: NetworkManager.shared.DeleteContact) else {
            return
        }
       
        NetworkManager.shared.postRequest(url: url, headers: nil, params: params) { (response) in
            if self.parseResponse(response: response) {
                let index_1 = self.realContactList.firstIndex { (item) -> Bool in
                    return item.id == contact.id
                }
                if index_1 != nil {
                    self.realContactList.remove(at: index_1!)
                }
                let index_2 = self.contactList.firstIndex { (item) -> Bool in
                    return contact.id == item.id
                }
                if index_2 != nil {
                    self.contactList[index_2!].d_last_msg_id = contact.last_msg_id
                }
                
//                let params = [
//                    "c_id": contact.id,
//                    "t_id": contact.t_id
//                ]
//                self.socketIOManager.deleteContact(params: params)
            } else {
                let message = response["err_msg"].stringValue
                self.showToastMessage(message: message)
            }
            self.refreshControl.endRefreshing()
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
        if contact.last_msg_status == "unread" && contact.last_msg_sender_id == contact.t_id {
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
            let row = indexPath.row
            if self.realContactList.count > row {
                let contact = self.realContactList.remove(at: row)
                self.deleteContact(contact)

                self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .fade)
            }
        }
    }
    
}

//extension MainViewController: SocketIOManagerDelegate {
//
//    func messageReceived(result: JSON) {
//        if result.arrayValue.count > 0 {
//            let message =  result.arrayValue[0]
//            if let chatView = self.navigationController?.viewControllers.last as? ChatViewController {
//                chatView.onMessageAdded(message)
//            }
//        }
//    }
//
//    func lastMessageUpdated(result: JSON) {
//        if result.arrayValue.count > 0 {
//            let message =  result.arrayValue[0]
//            let c_id = message["c_id"].intValue
//
//            let index = self.contactList.firstIndex { (contact) -> Bool in
//                return contact.id == c_id
//            }
//            if index != nil {
//                let contact = self.contactList[index!]
//                contact.last_msg_sender_id = message["f_id"].intValue
//                contact.last_msg = message["msg_content"].stringValue
//                contact.last_msg_type = message["msg_type"].stringValue
//                contact.last_msg_status = message["msg_status"].stringValue
//                contact.last_msg_timestamp = message["msg_timestamp"].doubleValue
//
//                let index_1 = self.realContactList.firstIndex { (contact) -> Bool in
//                    return contact.id == c_id
//                }
//                if index_1 != nil {
//                    self.realContactList[index_1!] = contact
//                    self.sortContact()
//                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0), IndexPath(row: index_1!, section: 0)], with: .none)
//                } else {
//                    self.loadContactTable()
//                }
//            }
//        }
//    }
//
//    func readMessage(result: JSON) {
//        if result.arrayValue.count > 0 {
//            let message =  result.arrayValue[0]
//            if let chatView = self.navigationController?.viewControllers.last as? ChatViewController {
//                chatView.updateMessage(message)
//            }
//        }
//    }
//
//    func readAllMessage(result: JSON) {
//        if result.arrayValue.count > 0 {
//            let message =  result.arrayValue[0]
//            if let chatView = self.navigationController?.viewControllers.last as? ChatViewController {
//                chatView.updateMessage(message)
//            }
//        }
//    }
//
//    func contactCreated(result: JSON) {
//        if result.arrayValue.count > 0 {
//            let tmp =  result.arrayValue[0]
//            if let curUser = CurrentUser {
//                let contact = ContactModel(tmp, curUser)
//                let c_id = contact.id
//                let index = self.contactList.firstIndex { (contact) -> Bool in
//                    return contact.id == c_id
//                }
//                if index == nil {
//                    self.contactList.insert(contact, at: 0)
//                }
//            }
//        }
//    }
//
//    func userTyping(result: JSON) {
//        if result.arrayValue.count > 0 {
//            let item = result.arrayValue[0]
//            let c_id = item["c_id"].intValue
//            let typing = item["typing"].intValue == 0 ? false : true
//            let index = self.realContactList.firstIndex { (contact) -> Bool in
//                return contact.id == c_id
//            }
//            if index != nil {
//                let contact = self.realContactList[index!]
//                contact.isTyping = typing
//                self.realContactList[index!] = contact
//                self.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .none)
//            }
//
//            if let chatView = self.navigationController?.viewControllers.last as? ChatViewController {
//                if chatView.contact != nil && chatView.contact.id == c_id {
//                    chatView.setTypingStatus(typing: typing)
//                }
//            }
//        }
//    }
//
//    func deleteContact(result: JSON) {
//        if result.arrayValue.count > 0 {
//            let item = result.arrayValue[0]
//            let c_id = item["c_id"].intValue
//            let index_1 = self.realContactList.firstIndex { (item) -> Bool in
//                return item.id == c_id
//            }
//            if index_1 != nil {
//                self.realContactList.remove(at: index_1!)
//                self.tableView.deleteRows(at: [IndexPath(row: index_1!, section: 0)], with: .fade)
//            }
//            let index_2 = self.contactList.firstIndex { (item) -> Bool in
//                return item.id == c_id
//            }
//            if index_2 != nil {
//                self.contactList.remove(at: index_2!)
//            }
//        }
//    }
//}
//
