//
//  ChatViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/17/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController
import SCSDKLoginKit
import SCSDKBitmojiKit

class ChatViewController: JSQMessagesViewController {
    var externalID:String = ""
    var userEntity: UserEntity?
    var otherUserID:String = ""
    var otherUserDisplayName:String = ""
    var amIAnon = false
    var areTheyAnon = false
    var messages = [JSQMessage]()
    var button = dropDownBtn()
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: FaxxPink)
    }()

    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addTitle(title: otherUserDisplayName)
        print("EXTRNL")
        print(externalID)
        
//        print(userEntity as Any)
//        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
        print("Am I anon in viewDidLoad Chat")
        print(amIAnon)
        if amIAnon {
            senderId = "ZAAAAA3AAAAAZ" + externalID
        } else {
            senderId = externalID
        }
        print(amIAnon)
        senderDisplayName = ""
        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        let messageDataRefMe = Constants.refs.databaseRoot.child("messageData").child(self.externalID).child(self.otherUserID)
        let query = messageDataRefMe.queryLimited(toLast: 10000)
        _ = query.observe(.childAdded, with: { [weak self] snapshot in
            print("lmaoooo")
            print(snapshot)

            if  let data        = snapshot.value as? [String: String],
                let id          = data["sender_id"],
                let text        = data["text"],
                !text.isEmpty
            {
                if let message = JSQMessage(senderId: id, displayName: "", text: text)
                {
                    self?.messages.append(message)

                    self?.finishReceivingMessage()
                }
            }
        })
        
        button = dropDownBtn.init(frame: CGRect(x:0, y:0, width: 0, height:0))
        button.setTitle("Menu", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = true
        self.view.addSubview(button)
        
        //position button
        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        //button dims
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        button.heightAnchor.constraint(equalToConstant: 140).isActive = true
        
        button.dropView.dropDownOptions = ["Block", "Clear Chat", "Reveal Identity"]
        

    }
    
    
    @objc func backPressed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "main") as!MainViewController
        newViewController.userEntity = userEntity
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.modalPresentationStyle = .custom
        self.present(newViewController, animated: true, completion: nil)
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData!
    {
        return messages[indexPath.item]
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource!
    {
        return messages[indexPath.item].senderId == senderId ? outgoingBubble : incomingBubble
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource!
    {
        return nil
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
    {
        return messages[indexPath.item].senderId == senderId ? nil : NSAttributedString(string: messages[indexPath.item].senderDisplayName)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        return messages[indexPath.item].senderId == senderId ? 0 : 15
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!)
    {

        let d = Int(Date().timeIntervalSinceReferenceDate)
        let message = ["sender_id": senderId, "text": text]
        
        var messageDataRefThem = Constants.refs.databaseRoot.child("messageData")
        var messageDataRefMe = Constants.refs.databaseRoot.child("messageData")
        var userDataRefThem = Constants.refs.databaseRoot.child("UserData")
        var userDataRefMe = Constants.refs.databaseRoot.child("UserData")
        
        print("Chat pressed send data:")
        print("Am i Anon?")
        print(amIAnon)
        print("Are they anon?")
        print(areTheyAnon)
        
        if areTheyAnon{
            if amIAnon{
                userDataRefMe = Constants.refs.databaseRoot.child("UserData").child("ZAAAAA3AAAAAZ" + self.externalID).child("ZAAAAA3AAAAAZ" + self.otherUserID)
                messageDataRefMe = Constants.refs.databaseRoot.child("messageData").child("ZAAAAA3AAAAAZ" + self.externalID).child("ZAAAAA3AAAAAZ" + self.otherUserID).childByAutoId()
                userDataRefThem = Constants.refs.databaseRoot.child("UserData").child("ZAAAAA3AAAAAZ" + self.otherUserID).child("ZAAAAA3AAAAAZ" + self.externalID)
                messageDataRefThem = Constants.refs.databaseRoot.child("messageData").child("ZAAAAA3AAAAAZ" + self.otherUserID).child("ZAAAAA3AAAAAZ" + self.externalID).childByAutoId()
            } else {
                userDataRefMe = Constants.refs.databaseRoot.child("UserData").child(self.externalID).child("ZAAAAA3AAAAAZ" + self.otherUserID)
                messageDataRefMe = Constants.refs.databaseRoot.child("messageData").child(self.externalID).child("ZAAAAA3AAAAAZ" + self.otherUserID).childByAutoId()
                userDataRefThem = Constants.refs.databaseRoot.child("UserData").child("ZAAAAA3AAAAAZ" + self.otherUserID).child(self.externalID)
                messageDataRefThem = Constants.refs.databaseRoot.child("messageData").child("ZAAAAA3AAAAAZ" + self.otherUserID).child(self.externalID).childByAutoId()
            }
        } else {
            if amIAnon{
                userDataRefMe = Constants.refs.databaseRoot.child("UserData").child("ZAAAAA3AAAAAZ" + self.externalID).child(self.otherUserID)
                messageDataRefMe = Constants.refs.databaseRoot.child("messageData").child("ZAAAAA3AAAAAZ" + self.externalID).child(self.otherUserID).childByAutoId()
                userDataRefThem = Constants.refs.databaseRoot.child("UserData").child(self.otherUserID).child("ZAAAAA3AAAAAZ" + self.externalID)
                messageDataRefThem = Constants.refs.databaseRoot.child("messageData").child(self.otherUserID).child("ZAAAAA3AAAAAZ" + self.externalID).childByAutoId()
            } else {
                userDataRefMe = Constants.refs.databaseRoot.child("UserData").child(self.externalID).child(self.otherUserID)
                messageDataRefMe = Constants.refs.databaseRoot.child("messageData").child(self.externalID).child(self.otherUserID).childByAutoId()
                userDataRefThem = Constants.refs.databaseRoot.child("UserData").child(self.otherUserID).child(self.externalID)
                messageDataRefThem = Constants.refs.databaseRoot.child("messageData").child(self.otherUserID).child(self.externalID).childByAutoId()
                
            }
            
        }
        
        print(userDataRefThem)
        print(userDataRefMe)
        print(messageDataRefThem)
        print(messageDataRefMe)
        messageDataRefThem.setValue(message)
        userDataRefThem.child("time").setValue(d)
        userDataRefThem.child("isNew").setValue(true)
        
        messageDataRefMe.setValue(message)
        userDataRefMe.child("time").setValue(d)

        incrementScore(senderID: self.externalID, recieiverID: userDataRefThem)
        finishSendingMessage()
    }
    
    func incrementScore(senderID:Any, recieiverID:Any){
        
    }
        
    
}

class dropDownBtn: UIButton {
    
    var dropView = dropDownView()
    var height = NSLayoutConstraint()
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.darkGray
        
        dropView = dropDownView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        
        dropView.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    override func didMoveToSuperview() {
        self.superview?.addSubview(dropView)
        self.superview?.bringSubview(toFront: dropView)
        dropView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        dropView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dropView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        height = dropView.heightAnchor.constraint(equalToConstant: 0)
    }
    
    var isOpen = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isOpen == false {
            isOpen = true
            NSLayoutConstraint.deactivate([self.height])
            if self.dropView.tableView.contentSize.height > 150 {
                self.height.constant = 150
            } else {
                self.height.constant = self.dropView.tableView.contentSize.height
            }
                
            NSLayoutConstraint.activate([self.height])
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropView.layoutIfNeeded()
                self.dropView.center.y += self.dropView.frame.height / 2
            }, completion: nil)
        }else{
            isOpen = false
            
            NSLayoutConstraint.deactivate([self.height])
            self.height.constant = 0
            NSLayoutConstraint.activate([self.height])
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropView.center.y -= self.dropView.frame.height / 2
                self.dropView.layoutIfNeeded()
                
            }, completion: nil)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
 
 
class dropDownView: UIView, UITableViewDelegate, UITableViewDataSource {
    var dropDownOptions = [String]()
    var tableView = UITableView()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableView.backgroundColor = UIColor.darkGray
        self.backgroundColor = UIColor.darkGray
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(tableView)
        
        tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dropDownOptions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath : IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
       
        cell.textLabel?.text = dropDownOptions[indexPath.row]
        cell.backgroundColor = UIColor.darkGray
        
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(dropDownOptions[indexPath.row])
    }
}
