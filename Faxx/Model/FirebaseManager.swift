//
//  FirebaseManager.swift
//  Faxx
//
//  Created by Raul Cheng on 11/11/20.
//

import Foundation
import Firebase
import FirebaseCore
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage
import SwiftyJSON

protocol FirebaseManagerDelegate {
    func onUserAdded(_ user: UserContact)
    func onSelfStateChanged(_ state: UserContact)
    func onMessageAdded(_ message: MockMessage)
    func setTypingStatus(_ otherUserId: String, _ typing: Bool)
    func updateMessage(_ message: MockMessage)
}

class FirebaseManager: NSObject {
    
    var databaseRoot: DatabaseReference!
    var userDataRef: DatabaseReference!
    var messageDataRef: DatabaseReference!
    var imageMessageStorageRef: StorageReference!
    var avatarStorageRef: StorageReference!
    
    let ServerKey = "AAAACohhKo4:APA91bH40mqD_xJ7fNYAbAJSJN7QwNRqpL3KEIdO6LFu58of2R7eOha7A4As64LE6BKMEoH7N183CzWIzwJTncmxCQqSOvqj91uL9i1wvzWTNsYOIUTQXzpKmEa0W6_AybtBijO43wdf"
    
    var delegate: FirebaseManagerDelegate?
    
    override init() {
        super.init()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        
        let db = Firestore.firestore()
        db.settings = settings
        
        databaseRoot = Database.database().reference()
        userDataRef = databaseRoot.child("UserData")
        messageDataRef = databaseRoot.child("messageData")
        imageMessageStorageRef = Storage.storage().reference().child("messages_assets")
        avatarStorageRef = Storage.storage().reference().child("avatars")
    }
    
    func updateUser(_ userId: String, _ info: [String : Any]) {
        userDataRef.child(userId).child("Info").child("Age").setValue(info["Age"] as? Int ?? 1000)
        userDataRef.child(userId).child("Info").child("Avatar").setValue(info["Avatar"] as? String ?? "")
        userDataRef.child(userId).child("Info").child("DisplayName").setValue(info["DisplayName"] as? String ?? "")
        userDataRef.child(userId).child("Info").child("FCM_Token").setValue(info["FCM_Token"] as? String ?? "")
        userDataRef.child(userId).child("Info").child("Sex").setValue(info["Sex"] as? String ?? "Other")
    }
    
    func setAnonUser(_ externalID: String, _ posterId: String, _ user_info: [String : Any], _ poster_info: [String : Any]) {
        let gender = user_info["Sex"] as? String ?? "Other"
        let avatar_str = getRandomAvatar(gender)
        let avatar = UIImage(named: avatar_str) ?? #imageLiteral(resourceName: "Tractor_Other")
        let userId = AnnoymousIdPrefix + externalID
        uploadRandomAvatar(userId, avatar) { (avatarUrl) in
            self.updateUserInfo(self.userDataRef.child(externalID).child(posterId).child("Info"), poster_info)

            var annon_info = user_info
            annon_info["DisplayName"] = avatar_str.components(separatedBy: "_").first ?? ""
            annon_info["Avatar"] = avatarUrl == "" ? DefaultAvatarUrl : avatarUrl
            self.updateUserInfo(self.userDataRef.child(posterId).child(userId).child("Info"), annon_info)
        }
    }
    
    func updateUserInfo(_ userRef: DatabaseReference, _ info: [String : Any]) {
        userRef.child("Age").setValue(info["Age"] as? Int ?? 1000)
        userRef.child("Avatar").setValue(info["Avatar"] as? String ?? DefaultAvatarUrl)
        userRef.child("DisplayName").setValue(info["DisplayName"] as? String ?? "")
        userRef.child("FCM_Token").setValue(info["FCM_Token"] as? String ?? "")
        userRef.child("Sex").setValue(info["Sex"] as? String ?? "Other")
    }
    
    func uploadRandomAvatar(_ userId: String, _ avatar: UIImage, completion: @escaping (String)->Void) {
        let file_path = avatarStorageRef.child("\(userId).png")
        file_path.putData(avatar.pngData() ?? Data(), metadata: nil) { (metaData, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
            } else {
                file_path.downloadURL(completion: { (url, error) in
                    print("Image URL: \((url?.absoluteString ?? ""))")
                    completion(url?.absoluteString ?? "")
                })
            }
        }
    }
    
    func getNotificationSender(_ userId: String, _ otherId: String, completion: @escaping (JSON)->Void) {
        userDataRef.child(userId).child(otherId).child("Info").observeSingleEvent(of: .value, with: { (snp) in
            let userInfo = JSON(snp.value as? [String : Any] ?? [:])
            completion(userInfo)
        })
    }
    
    func observeNewUser(_ userId: String) {
        userDataRef.child(userId).queryLimited(toLast: 100).observe(.childAdded, with: { [weak self] snapshot in
            let theirID = String(snapshot.key)
            if theirID == "Info" {
                let info = snapshot.value as! NSDictionary
                let user = UserContact(userId, info)
                self?.delegate?.onUserAdded(user)
            } else {
                let snpsht = snapshot.value as! NSDictionary
                if let theirInfo = snpsht["Info"] as? NSDictionary {
                    if theirInfo["time"] as? Double != nil {
                        let user = UserContact(theirID, theirInfo)
                        self?.delegate?.onUserAdded(user)
                    }
                }
            }
        })
    }
    
    func observeMessageThread(_ userId: String, _ theirId: String) {
        userDataRef.child(userId).child(theirId).observe(.value, with: { [weak self] snapshot in
            if let snpsht = snapshot.value as? NSDictionary, let info = snpsht["Info"] as? NSDictionary {
                self?.delegate?.onSelfStateChanged(UserContact(theirId, info))
            }
        })
        self.observeTypingStatus(theirId)
    }
   
    func setNewUserContact(_ userId: String, _ theirId: String, _ state: Bool) {
        userDataRef.child(userId).child(theirId).child("Info").child("isNew").setValue(state)
    }
    
    func observeMessageAdded(_ curUser: MockUser, _ otherUser: MockUser) {
        messageDataRef.child(curUser.senderId).child(otherUser.senderId).queryLimited(toLast: 10000).observe(.childAdded, with: { [weak self] snapshot in
            if  let data = snapshot.value as? NSDictionary,
                let id = data["sender_id"] as? String,
                let type = data["type"] as? String {
                if type == "text" {
                    let date = Date(timeIntervalSince1970: data["date"] as? Double ?? getCurrentUtcTimeInterval())
                    let unread = data["unread"] as? Bool ?? false
                    let message = data["message"] as? String ?? ""
                    if !message.isEmpty {
                        let key = String(snapshot.key)
                        if (id == curUser.senderId) {
                            let message = MockMessage(text: message, user: curUser, messageId: key, date: date, unread: unread)
                            self?.delegate?.onMessageAdded(message)
                        } else {
                            let message = MockMessage(text: message, user: otherUser, messageId: key, date: date, unread: unread)
                            self?.delegate?.onMessageAdded(message)
                        }
                    }
                } else if type == "image" {
                    let date = Date(timeIntervalSince1970: data["date"] as? Double ?? getCurrentUtcTimeInterval())
                    let unread = data["unread"] as? Bool ?? false
                    let key = String(snapshot.key)
                    if let url = URL(string: (data["url"] as? String ?? "")) {
                        if (id == curUser.senderId) {
                            let message = MockMessage(imageURL: url, user: curUser, messageId: key, date: date, unread: unread)
                            self?.delegate?.onMessageAdded(message)
                        } else {
                            let message = MockMessage(imageURL: url, user: otherUser, messageId: key, date: date, unread: unread)
                            self?.delegate?.onMessageAdded(message)
                        }
                    }
                } else if type == "video" {
                    let date = Date(timeIntervalSince1970: data["date"] as? Double ?? getCurrentUtcTimeInterval())
                    let unread = data["unread"] as? Bool ?? false
                    let key = String(snapshot.key)
                    if let url = URL(string: (data["url"] as? String ?? "")) {
                        if let thumb = URL(string: (data["thumb"] as? String ?? "")) {
                            if (id == curUser.senderId) {
                                let message = MockMessage(thumbnailURL: thumb, videoURL: url, user: curUser, messageId: key, date: date, unread: unread)
                                self?.delegate?.onMessageAdded(message)
                            } else {
                                 let message = MockMessage(thumbnailURL: thumb, videoURL: url, user: otherUser, messageId: key, date: date, unread: unread)
                                self?.delegate?.onMessageAdded(message)
                            }
                        }
                    }
                }
            }
            
        })
    }
    
    func sendMessage(_ curUser: MockUser, _ otherUser: MockUser, _ message: [String : Any], _ fcm_token: String, _ senderUserName: String) {
        let senderIdMe = curUser.senderId
        let senderIdOther = otherUser.senderId
        sendMessageToUser(senderIdMe, senderIdOther, message)
        
        self.setUserEndTyping(curUser.senderId)
        
        let type = message["type"] as? String ?? ""
        var type_str = "message"
        if type == "image" {
            type_str = "image"
        } else if type == "video" {
            type_str = "video"
        }
        var body = ""
        if type == "text" {
            body = message["message"] as? String ?? ""
        }
        let data = [
            "senderId": senderIdMe,
            "isAnon": !senderIdOther.hasPrefix(AnnoymousIdPrefix)
        ] as [String : Any]
        self.sendPushNotification(fcm_token, String(format: SentMessageFormat, senderUserName, type_str), body, data)
    }
    
    func sendMessageToUser(_ senderId: String, _ otherId: String, _ message: [String : Any]) {
        var senderId_2 = senderId
        var otherId_2 = otherId
        if otherId.hasPrefix(AnnoymousIdPrefix) {
            otherId_2 = String(otherId_2.dropFirst(AnnoymousIdPrefix.count))
        } else {
            senderId_2 = "\(AnnoymousIdPrefix)\(senderId_2)"
        }
        let userDataRefMe = userDataRef.child(senderId).child(otherId)
        let userDataRefThem = userDataRef.child(otherId_2).child(senderId_2)
        let messageDataRefMe = messageDataRef.child(senderId).child(otherId)
        let messageDataRefThem = messageDataRef.child(otherId_2).child(senderId_2)
        let messageId: String = messageDataRefMe.childByAutoId().key ?? ""
        
        let d = Int(getCurrentUtcTimeInterval())
        var message_other = message
        message_other["unread"] = true
        message_other["sender_id"] = senderId_2
        messageDataRefThem.child(messageId).setValue(message_other)
        userDataRefThem.child("Info").child("time").setValue(d)
        userDataRefThem.child("Info").child("isNew").setValue(true)
        
        var message_me = message
        message_me["unread"] = true
        messageDataRefMe.child(messageId).setValue(message_me)
        userDataRefMe.child("Info").child("time").setValue(d)
    }
    
    func sendImage(_ curUser: MockUser, _ otherUser: MockUser, _ image: UIImage, _ fcm_token: String, _ senderUserName: String) {
        let message_push_id = messageDataRef.child(curUser.senderId).child(otherUser.senderId).childByAutoId().key ?? ""
        let file_path = imageMessageStorageRef.child("\(message_push_id).jpg")
        file_path.putData(image.jpegData(compressionQuality: 1) ?? Data(), metadata: nil) { (metaData, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
            } else {
                file_path.downloadURL(completion: { (url, error) in
                    print("Image URL: \((url?.absoluteString ?? ""))")
                    let message = [
                        "url": url?.absoluteString ?? "",
                        "type": "image",
                        "sender_id": curUser.senderId,
                    ] as [String: Any]
                    self.sendMessage(curUser, otherUser, message, fcm_token, senderUserName)
                })
            }
        }
    }
    
    func sendVideo(_ curUser: MockUser, _ otherUser: MockUser, _ video: Data, _ extension_str: String, _ thumb: UIImage, _ fcm_token: String, _ senderUserName: String) {
        let message_push_id = messageDataRef.child(curUser.senderId).child(otherUser.senderId).childByAutoId().key ?? ""
        let video_path = imageMessageStorageRef.child("\(message_push_id).\(extension_str)")
        let image_path = imageMessageStorageRef.child("\(message_push_id).jpg")
        video_path.putData(video, metadata: nil) { (metaData, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
            } else {
                video_path.downloadURL(completion: { (url, error) in
                    let video_url = url?.absoluteString ?? ""
                    image_path.putData(thumb.jpegData(compressionQuality: 1) ?? Data(), metadata: nil) { (metaData, error) in
                        if error != nil {
                            print(error?.localizedDescription ?? "")
                        } else {
                            image_path.downloadURL(completion: { (url, error) in
                                let message = [
                                    "thumb": url?.absoluteString ?? "",
                                    "url": video_url,
                                    "type": "video",
                                    "sender_id": curUser.senderId,
                                ] as [String: Any]
                                self.sendMessage(curUser, otherUser, message, fcm_token, senderUserName)
                            })
                        }
                    }
                })
            }
        }
    }
    
    func setUserTyping(_ userId: String) {
        userDataRef.child(userId).child("Info").child("typing").setValue(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.setUserEndTyping(userId)
        }
    }
    
    func setUserEndTyping(_ userId: String) {
        userDataRef.child(userId).child("Info").child("typing").setValue(false)
    }
    
    func observeTypingStatus(_ otherUserId: String) {
        userDataRef.child(otherUserId).child("Info").child("typing").observe(.value, with: { [weak self] snapshot in
            let typing = snapshot.value as? Bool ?? false
            self?.delegate?.setTypingStatus(otherUserId, typing)
        })
    }
    
    func observeMessageStatus(_ senderUser: MockUser, _ otherUser: MockUser, _ message: MockMessage) {
        messageDataRef.child(senderUser.senderId).child(otherUser.senderId).child(message.messageId).child("unread").observe(.value) { [weak self] snapshot in
            let unread = snapshot.value as? Bool ?? false
            var tmp = message
            tmp.unread = unread
            self?.delegate?.updateMessage(tmp)
        }
    }
    
    func setReadMessage(_ senderUser: MockUser, _ otherUser: MockUser, _ message: MockMessage) {
        let senderId = senderUser.senderId
        let otherId = otherUser.senderId
        var senderId_2 = senderId
        var otherId_2 = otherId
        if otherId.hasPrefix(AnnoymousIdPrefix) {
            otherId_2 = String(otherId_2.dropFirst(AnnoymousIdPrefix.count))
        } else {
            senderId_2 = "\(AnnoymousIdPrefix)\(senderId_2)"
        }
        let messageDataRefMe = messageDataRef.child(senderId).child(otherId)
        let messageDataRefThem = messageDataRef.child(otherId_2).child(senderId_2)
        
        messageDataRefMe.child(message.messageId).child("unread").setValue(false)
        messageDataRefThem.child(message.messageId).child("unread").setValue(false)
    }
    
    func sendPushNotification(_ target_token: String, _ title: String, _ body: String, _ data: [String : Any]) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = [
            "to" : target_token,
            "notification" : [
                "title" : title,
                "body" : body
            ],
            "data" : data
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(ServerKey)", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()

    }
}
