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

        finishSendingMessage()
    }
    
    
}

