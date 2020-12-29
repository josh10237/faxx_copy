//
//  ChatViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/17/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import Foundation
import UIKit
import MessageKit
import InputBarAccessoryView
import SCSDKLoginKit
import SCSDKBitmojiKit
import PINRemoteImage
import SnapKit
import NBBottomSheet
import Lumina
import Lightbox
import BSImagePicker
import Photos
import AVFoundation
import SwiftyJSON

class ChatViewController: MessagesViewController, MessagesDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        guard let result = image.upOrientationImage() else {
            return
        }
        
        self.uploadChatImage(result)
        
    }

    // MARK: - SocketManager Callback
    
    func uploadChatImage(_ image: UIImage) {
        if contact != nil {
            
            if !NetworkManager.shared.isConnectedNetwork() {
                return
            }
            
            let url = NetworkManager.shared.UploadChatImage
           
            NetworkManager.shared.uploadImage(image: image, url: url) { (response) in
                if self.parseResponse(response: response) {
                    let url = response["url"].stringValue
                    let message = [
                        "c_id": self.contact.id,
                        "t_id": self.contact.t_id,
                        "type": "image",
                        "message": url,
                        "push_token": self.contact.t_fcm_token
                    ] as [String : Any]
                    self.socketIOManager.sendMessage(params: message)
                    
                    let token = self.contact.t_fcm_token
                    var displayName = self.contact.f_display_name
                    if self.contact.amIAnon {
                        displayName = self.contact.f_anon_display_name
                    }
                    let data = [
                        "senderId": self.contact.f_id,
                        "isAnon": self.contact.amIAnon
                    ] as [String : Any]
                    self.firebaseManager.sendPushNotification(token, String(format: SentMessageFormat, displayName, "Image"), "", data)
                } else {
                    let message = response["err_msg"].stringValue
                    self.showToastMessage(message: message)
                }
            }
        }
    }
    
    func updateMessage(_ item: JSON) {
        if let message = self.getMockMessageItem(item) {
            let index = messageList.firstIndex { (item) -> Bool in
                return item.messageId == message.messageId
            }
            if index != nil {
                if !message.unread {
                    isTyping = false
                }
                messageList[index!] = message
                self.messagesCollectionView.reloadItems(at: [IndexPath(row: 0, section: index!)])
            }
        }
    }
    
    func setTypingStatus(typing: Bool) {
        let isHidden = !typing
        setTypingIndicatorViewHidden(isHidden, animated: true, whilePerforming: nil) { [weak self] success in
            if success, self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    func onMessageAdded(_ item: JSON) {
        if let message = self.getMockMessageItem(item) {
            let index = messageList.firstIndex { (item) -> Bool in
                return item.messageId == message.messageId
            }
            if index == nil {
                self.insertMessage(message)
            } else {
                messageList[index!] = message
                self.messagesCollectionView.reloadItems(at: [IndexPath(row: 0, section: index!)])
            }
            if message.unread && message.sender.senderId == otherUser.senderId {
                let params = [
                    "msg_id": message.messageId,
                    "c_id": contact.id
                ] as [String : Any]
                socketIOManager.readMessage(params: params)
            }
        }
    }
    
    // MARK: - Public properties

    /// The `BasicAudioController` controll the AVAudioPlayer state (play, pause, stop) and udpate audio cell UI accordingly.
    lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)

    lazy var messageList: [MockMessage] = []
   
    // MARK: - Private properties

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // MARK: - User Info
    
    var externalID: String = ""
    var userEntity: UserEntity?
    var otherUserID: String = ""
    var otherUserAvatar: String = ""
    var otherUserDisplayName: String = ""
    var otherUserPushToken: String = ""
    var areTheyAnon = false
    var currentUser: UserContact?
    var contact: ContactModel!
    
    var curUser: MockUser!
    var otherUser: MockUser!
    
    var isTyping: Bool = false
    
    var firebaseManager: FirebaseManager = FirebaseManager()
    
    var socketIOManager = SocketIOManager.shared
    
    let camera = LuminaViewController()
    
    // MARK: - Lifecycle
    
    let outgoingAvatarOverlap: CGFloat = 17.5
  
    var avatar: Avatar!
    
    override func viewDidLoad() {
        
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout())
        messagesCollectionView.register(MessageCell.self)
        
        super.viewDidLoad()
        
        configureMessageCollectionView()
        configureMessageInputBar()

        if contact != nil {
            self.curUser = MockUser(senderId: "\(contact.f_id)", displayName: contact.f_display_name)
            if contact.areTheyAnon {
                self.addTitle(title: contact.t_anon_display_name)
                self.otherUser = MockUser(senderId: "\(contact.t_id)", displayName: contact.t_anon_display_name)
            } else {
                self.addTitle(title: contact.t_display_name)
                self.otherUser = MockUser(senderId: "\(contact.t_id)", displayName: contact.t_display_name)
            }
            
            let params = [
                "c_id": contact.id
            ]
            self.socketIOManager.readAllMessage(params: params)
            
            self.socketIOManager.createContact(params: contact.getJSON())
        }
        
        loadData()
        socketIOManager.establishConnection(user_id: CurrentUser?.id ?? 0)
        
    }
    
    func getMockMessageItem(_ item: JSON) -> MockMessage? {
        var message: MockMessage? = nil
        let msg_id = item["id"].stringValue
        let f_id = item["f_id"].intValue
        let type = item["msg_type"].stringValue
        if type == "text" {
            let date = Date(timeIntervalSince1970: item["msg_timestamp"].doubleValue)
            let unread = item["msg_status"].stringValue == "unread"
            let content = item["msg_content"].stringValue
            if !content.isEmpty {
                if (f_id == self.contact.f_id) {
                    message = MockMessage(text: content, user: self.curUser, messageId: msg_id, date: date, unread: unread)
                } else {
                    message = MockMessage(text: content, user: self.otherUser, messageId: msg_id, date: date, unread: unread)
                }
            }
        } else if type == "image" {
            let date = Date(timeIntervalSince1970: item["msg_timestamp"].doubleValue)
            let unread = item["msg_status"].stringValue == "unread"
            if let url = URL(string: (item["msg_content"].stringValue)) {
                if (f_id == self.contact.f_id) {
                    message = MockMessage(imageURL: url, user: self.curUser, messageId: msg_id, date: date, unread: unread)
                } else {
                    message = MockMessage(imageURL: url, user: self.otherUser, messageId: msg_id, date: date, unread: unread)
                }
            }
        }
        return message
    }
    
    func loadData() {
        if contact != nil {
            let params = [
                "c_id": contact.id
            ] as [String : Any]
            
            if !NetworkManager.shared.isConnectedNetwork() {
                return
            }
            
            guard let url = URL(string: NetworkManager.shared.AllMessages) else {
                return
            }
           
            NetworkManager.shared.postRequest(url: url, headers: nil, params: params) { (response) in
                if self.parseResponse(response: response) {
                    let tmp_list = response["list"].arrayValue
                    var result: [MockMessage] = []
                    tmp_list.forEach { (item) in
                        if let message = self.getMockMessageItem(item) {
                            result.append(message)
                        }
                    }
                    self.messageList = result
                    self.messagesCollectionView.reloadData()
                } else {
                    let message = response["err_msg"].stringValue
                    self.showToastMessage(message: message)
                }
            }
        }
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        messageInputBar.inputTextViewDidEndEditing()
        
        super.viewWillDisappear(animated)
    }
    
    func configureMessageCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false

        showMessageTimestampOnSwipeLeft = true // default false
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
        
        // Hide the outgoing avatar and adjust the label alignment to line up with the messages
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        layout?.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))

        // Set outgoing avatar to overlap with the message bubble
        layout?.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 18, bottom: outgoingAvatarOverlap, right: 0)))
        layout?.setMessageIncomingAvatarSize(.zero)
        layout?.setMessageIncomingMessagePadding(UIEdgeInsets(top: -outgoingAvatarOverlap, left: 0, bottom: outgoingAvatarOverlap, right: 18))
        
        layout?.setMessageIncomingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageIncomingAccessoryViewPadding(HorizontalEdgeInsets(left: 8, right: 0))
        layout?.setMessageIncomingAccessoryViewPosition(.messageBottom)
        layout?.setMessageOutgoingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageOutgoingAccessoryViewPadding(HorizontalEdgeInsets(left: 0, right: 8))

        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .primaryColor
        messageInputBar.sendButton.setTitleColor(.primaryColor, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.primaryColor.withAlphaComponent(0.3),
            for: .highlighted
        )
        
        messageInputBar.isTranslucent = true
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.tintColor = .primaryColor
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        configureInputBarItems()
    }

    private func configureInputBarItems() {
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.sendButton.imageView?.backgroundColor = UIColor(white: 0.85, alpha: 1)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        messageInputBar.sendButton.image = #imageLiteral(resourceName: "ic_up")
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.imageView?.layer.cornerRadius = 16
//
//        configureInputBarPadding()
//
        // This just adds some more flare
        messageInputBar.sendButton
            .onEnabled { item in
                UIView.animate(withDuration: 0.3, animations: {
                    item.imageView?.backgroundColor = FaxxDarkPink
                })
            }.onDisabled { item in
                UIView.animate(withDuration: 0.3, animations: {
                    item.imageView?.backgroundColor = UIColor(white: 0.85, alpha: 1)
                })
        }

        messageInputBar.setLeftStackViewWidthConstant(to: 40, animated: false)
        let cameraButton = InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(0)
                $0.image = UIImage(named: "camera")?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 40, height: 40), animated: false)
                $0.tintColor = FaxxDarkPink
            }.onTextViewDidChange { button, textView in
                button.isEnabled = textView.text.isEmpty
            }.onTouchUpInside {_ in
                self.openOptionSheet()
            }
        messageInputBar.setStackViewItems([cameraButton], forStack: .left, animated: false)
    }
    
    func openOptionSheet() {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SelectOptionController") as? SelectOptionController {
            vc.delegate = self
            let configuration = NBBottomSheetConfiguration(animationDuration: 0.4, sheetSize: .fixed(300))
            let bottomSheetController = NBBottomSheetController(configuration: configuration)
            bottomSheetController.present(vc, on: self)
        }
    }
    
    @objc func takePhotoAction() {
        self.dismiss(animated: true) {
            self.takePhoto()
        }
    }
    
    @objc func chooseCameraAction() {
        self.dismiss(animated: true) {
            self.selectAsset()
        }
    }
    
    private func configureInputBarPadding() {
    
        // Entire InputBar padding
        messageInputBar.padding.bottom = 8
        
        // or MiddleContentView padding
        messageInputBar.middleContentViewPadding.right = -38

        // or InputTextView padding
        messageInputBar.inputTextView.textContainerInset.bottom = 8
        
    }
    
    // MARK: - Lightbox

    func openLightBox(_ index: Int) {
        let cur_item = messageList[index]
        let items = messageList.filter { (item) -> Bool in
            return item.kind_str == "photo" || item.kind_str == "video"
        }
        let current_index = items.firstIndex { (item) -> Bool in
            return item.messageId == cur_item.messageId
        }
        
        var lightboxImages : [LightboxImage] = []
        for item in items {
            if item.kind_str == "photo" {
                let url = item.url
                if url != nil {
                    lightboxImages.append(
                        LightboxImage(
                            imageURL:  url!
                        )
                    )
                }
            } else {
                let thumb = item.thumbnail
                if thumb != nil {
                    let url = item.url
                    if url != nil {
                        lightboxImages.append(
                            LightboxImage(
                                image: UIImage.load(from: thumb!.absoluteString) ?? UIImage(),
                                text: "",
                                videoURL: url!
                            )
                        )
                    }
                }
            }
        }
        
        LightboxConfig.PageIndicator.enabled = false
        LightboxConfig.CloseButton.enabled = false
        LightboxConfig.preload = 5

        // Create an instance of LightboxController.
        let controller = LightboxController(images: lightboxImages, startIndex: current_index ?? 0)

        // Use dynamic background.
        controller.dynamicBackground = true

        // Present your controller.
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section - 1].user
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messageList.count else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section + 1].user
    }

    func insertMessage(_ message: MockMessage) {
        messageList.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
//            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: false)
//            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messageList.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
   
    // MARK: - UICollectionViewDataSource
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }

        // Very important to check this when overriding `cellForItemAt`
        // Super method will handle returning the typing indicator cell
        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }

        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(MessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }

    // MARK: - MessagesDataSource

    func currentSender() -> SenderType {
        return self.curUser
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.displayName
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

        if !isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message) {
            guard let tmp = message as? MockMessage else {
                return nil
            }
            if tmp.unread {
                return NSAttributedString(string: "√√", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.gray])
            } else {
                return NSAttributedString(string: "√√", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: FaxxPink])
            }
        }
        return nil
    }

}

// MARK: - MessageCellDelegate

extension ChatViewController: MessageCellDelegate {
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        self.openLightBox(messagesCollectionView.indexPath(for: cell)?.section ?? 0)
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }
    
    func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom cell label tapped")
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("Top message label tapped")
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }

    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }

    func didStartAudio(in cell: AudioMessageCell) {
        print("Did start playing audio sound")
    }

    func didPauseAudio(in cell: AudioMessageCell) {
        print("Did pause audio sound")
    }

    func didStopAudio(in cell: AudioMessageCell) {
        print("Did stop audio sound")
    }

    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
    }

}

// MARK: - MessageLabelDelegate

extension ChatViewController: MessageLabelDelegate {
    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }

    func didSelectHashtag(_ hashtag: String) {
        print("Hashtag selected: \(hashtag)")
    }

    func didSelectMention(_ mention: String) {
        print("Mention selected: \(mention)")
    }

    func didSelectCustom(_ pattern: String, match: String?) {
        print("Custom data detector patter selected: \(pattern)")
    }
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {

    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        if contact != nil {
            var params = [
                "c_id": contact.id,
                "t_id": contact.t_id,
                "typing": 1
            ]
            socketIOManager.userTyping(params: params)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                params["typing"] = 0
                self.socketIOManager.userTyping(params: params)
            }
            if !isTyping {
                let token = contact.t_fcm_token
                var displayName = contact.f_display_name
                if contact.amIAnon {
                    displayName = contact.f_anon_display_name
                }
                let data = [
                    "senderId": self.contact.f_id,
                    "isAnon": contact.amIAnon
                ] as [String : Any]
                self.firebaseManager.sendPushNotification(token, String(format: TypingMessageFormat, displayName), "", data)
                isTyping = true
            }
        }
    }
    
    func processInputBar(_ inputBar: InputBarAccessoryView) {
        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in

            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }

        let components = inputBar.inputTextView.components
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        // Resign first responder for iPad split view
//        inputBar.inputTextView.resignFirstResponder()
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async { [weak self] in
                inputBar.sendButton.stopAnimating()
                inputBar.inputTextView.placeholder = " Aa"
                self?.insertMessages(components)
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }

    private func insertMessages(_ data: [Any]) {
        for component in data {
            if let str = component as? String {
                if contact != nil {
                    let message = [
                        "c_id": contact.id,
                        "t_id": contact.t_id,
                        "type": "text",
                        "message": str,
                        "push_token": contact.t_fcm_token
                    ] as [String : Any]
                    self.socketIOManager.sendMessage(params: message)
                    
                    let token = contact.t_fcm_token
                    var displayName = contact.f_display_name
                    if contact.amIAnon {
                        displayName = contact.f_anon_display_name
                    }
                    let data = [
                        "senderId": self.contact.f_id,
                        "isAnon": contact.amIAnon
                    ] as [String : Any]
                    self.firebaseManager.sendPushNotification(token, String(format: SentMessageFormat, displayName, str), "", data)
                    
                    incrementScore(senderID: externalID, recieiverID: otherUserID)
                }
            }
        }
    }
    
    func incrementScore(senderID:String, recieiverID:String) {
        _ = UserDefaults.standard.dictionary(forKey: "scoreDict")
        if scoreDict[senderID] == nil {
            let myCurrentScore = 0//scoreDict[senderID] ?? 0
            let myCurrentScoreInt = myCurrentScore + 1
            scoreDict[senderID] = myCurrentScoreInt
        } else {
            var myCurrentScore = scoreDict[senderID]
            myCurrentScore = myCurrentScore! + 1
            scoreDict[senderID] = myCurrentScore
        }
        if scoreDict[recieiverID] == nil {
            var theirCurrentScore = scoreDict[recieiverID] ?? 0
            theirCurrentScore = 0
            let theirCurrentScoreInt = theirCurrentScore + 1
            scoreDict[recieiverID] = theirCurrentScoreInt
        } else {
            var theirCurrentScore = scoreDict[recieiverID] ?? 0
            theirCurrentScore = theirCurrentScore + 1
            scoreDict[recieiverID] = theirCurrentScore
        }
    }
    
    func selectAsset() {
        let imagePicker = ImagePickerController()
        imagePicker.settings.selection.max = 1
        imagePicker.settings.theme.selectionStyle = .checked
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.image, .video]
        imagePicker.settings.selection.unselectOnReachingMax = true

        var isSent: Bool = false
        
        self.presentImagePicker(imagePicker, select: { (asset) in
            print("Selected: \(asset)")
        }, deselect: { (asset) in
            print("Deselected: \(asset)")
        }, cancel: { (assets) in
            print("Canceled with selections: \(assets)")
        }, finish: { (assets) in
            print("Finished with selections: \(assets)")
            guard let asset = assets.first else { return }
            if (asset.mediaType == .image) {
                var imageRequestOptions: PHImageRequestOptions{
                    let options = PHImageRequestOptions()
                    options.version = .current
                    options.resizeMode = .exact
                    options.deliveryMode = .highQualityFormat
                    options.isNetworkAccessAllowed = true
                    options.isSynchronous = true
                    return options
                    
                }
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFit, options: imageRequestOptions) { (image, info) in
                    if image != nil {
                        if !isSent {
                            self.uploadChatImage(image!)
                            isSent = true
                        }
                    }
                }
            }
        }, completion: {
            print("select image completed")
        })
    }
    
    func takePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func getThumbnailImageFromVideoUrl(url: URL, completion: @escaping ((_ image: UIImage?)->Void)) {
        DispatchQueue.global().async { //1
            let asset = AVAsset(url: url) //2
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) //3
            avAssetImageGenerator.appliesPreferredTrackTransform = true //4
            let thumnailTime = CMTimeMake(value: 2, timescale: 1) //5
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) //6
                let thumbImage = UIImage(cgImage: cgThumbImage) //7
                DispatchQueue.main.async { //8
                    completion(thumbImage) //9
                }
            } catch {
                print(error.localizedDescription) //10
                DispatchQueue.main.async {
                    completion(nil) //11
                }
            }
        }
    }
    
}


// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {

    // MARK: - Text Messages

    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention:
            if isFromCurrentSender(message: message) {
                return [.foregroundColor: UIColor.white]
            } else {
                return [.foregroundColor: UIColor.primaryColor]
            }
        default: return MessageLabel.defaultAttributes
        }
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }

    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .primaryColor : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        var corners: UIRectCorner = []
        
        if isFromCurrentSender(message: message) {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
            if !isPreviousMessageSameSender(at: indexPath) {
                corners.formUnion(.topRight)
            }
            if !isNextMessageSameSender(at: indexPath) {
                corners.formUnion(.bottomRight)
            }
        } else {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomRight)
            if !isPreviousMessageSameSender(at: indexPath) {
                corners.formUnion(.topLeft)
            }
            if !isNextMessageSameSender(at: indexPath) {
                corners.formUnion(.bottomLeft)
            }
        }
        
        return .custom { view in
            let radius: CGFloat = 16
            let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            view.layer.mask = mask
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
//        avatarView.set(avatar: avatar)
//        avatarView.isHidden = isNextMessageSameSender(at: indexPath)
//        avatarView.layer.borderWidth = 2
//        avatarView.layer.borderColor = UIColor.primaryColor.cgColor
    }

    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if case MessageKind.photo(let media) = message.kind, let imageURL = media.url {
            imageView.pin_setImage(from: imageURL)
        } else {
            imageView.pin_cancelImageDownload()
        }
    }
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {

    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isTimeLabelVisible(at: indexPath) {
            return 18
        }
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isFromCurrentSender(message: message) {
            return !isPreviousMessageSameSender(at: indexPath) ? 20 : 0
        } else {
            return !isPreviousMessageSameSender(at: indexPath) ? (20 + outgoingAvatarOverlap) : 0
        }
    }

    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 0
    }

}

extension ChatViewController: SelectOptionDelegate {
    func onTakePhone() {
        self.takePhotoAction()
    }
    
    func onChooseFromCamera() {
        self.chooseCameraAction()
    }
    
    func onClose() {
        self.dismiss(animated: true, completion: nil)
    }
}
