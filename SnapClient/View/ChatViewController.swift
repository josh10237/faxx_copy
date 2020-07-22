//
//  ChatViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/17/20.
//  Copyright © 2020 Kboy. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController
import SCSDKLoginKit
import SCSDKBitmojiKit

//var externalID:String = ""

class ChatViewController: JSQMessagesViewController {
    var externalID:String = ""
    var userEntity: UserEntity?
    var messages = [JSQMessage]()
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: FaxxPink)
    }()

    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    override func viewDidLoad() {
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6))
        super.viewDidLoad()
        let barLayer = CALayer()
        let screenSize: CGRect = UIScreen.main.bounds
        let rectFrame: CGRect = CGRect(x:CGFloat(0), y:CGFloat(0), width:CGFloat(screenSize.width), height:CGFloat(70))
        barLayer.frame = rectFrame
        barLayer.backgroundColor = FaxxPink.cgColor
        view.layer.insertSublayer(barLayer, at: 1)
        
        let image = UIImage(named: "leftarrow_ICON")
        let backbutton = UIButton(type: UIButton.ButtonType.custom)
        backbutton.frame = CGRect(x: 100, y: 100, width: 200, height: 100)
        backbutton.setImage(image, for: .normal)
        backbutton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        backbutton.frame = CGRect(origin: CGPoint(x: 20, y: 35), size: CGSize(width:25,height: 25))
        self.view.addSubview(backbutton)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(backPressed))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        
        senderId = externalID
        senderDisplayName = ""


        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        let query = Constants.refs.databaseRoot.child(self.externalID).queryLimited(toLast: 10)

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
        let ref = Constants.refs.databaseRoot.child(self.externalID).childByAutoId()
        let message = ["sender_id": senderId, "text": text]

        ref.setValue(message)

        finishSendingMessage()
    }

    
}

