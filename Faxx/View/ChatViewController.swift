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
    var messages = [JSQMessage]()
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: FaxxPink)
    }()

    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    override func viewDidLoad() {
        self.addTitle(title: otherUserDisplayName)
        print("EXTRNL")
        print(userEntity?.externalID as Any)
        
        print(userEntity as Any)
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
        super.viewDidLoad()
        
        
        senderId = externalID
        senderDisplayName = ""
        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        let ref1 = Constants.refs.databaseRoot.child(self.externalID)
        let query = ref1.child(self.otherUserID).queryLimited(toLast: 10)
        _ = query.observe(.childAdded, with: { [weak self] snapshot in

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
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy/MM/dd HH:mm"
//        let currentDateTime = formatter.date(from: "2016/10/08 22:31")
        let d = String(Int(Date().timeIntervalSinceReferenceDate))
        let ref1 = Constants.refs.databaseRoot.child(self.externalID).child(self.otherUserID).childByAutoId()
        let ref2 = Constants.refs.databaseRoot.child(self.otherUserID).child(self.externalID).childByAutoId()
        let message = ["sender_id": senderId, "text": text, "time": d]
//        let d = Date().timeIntervalSinceReferenceDate
//        let ref1 = Constants.refs.databaseRoot.child(self.externalID).child(self.otherUserID).childByAutoId()
//        let ref2 = Constants.refs.databaseRoot.child(self.otherUserID).child(self.externalID).childByAutoId()
//        let message = ["sender_id": senderId, "text": text, "time": d] as [String : Any]

        ref1.setValue(message)
        ref2.setValue(message)

        finishSendingMessage()
    }
    
    
}

