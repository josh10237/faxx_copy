//
//  BaseChatViewController.swift
//  Faxx
//
//  Created by Raul Cheng on 11/15/20.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import BSImagePicker
import Photos
import AVFoundation
import Lightbox

/// A base class for the example controllers
class BaseChatViewController: MessagesViewController, MessagesDataSource, FirebaseManagerDelegate {
    
    // MARK: - Firebase Delegate
    
    func updateMessage(_ message: MockMessage) {
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
    
    func setTypingStatus(_ otherUserId: String, _ typing: Bool) {
        self.setTypingIndicatorViewHidden(!typing, animated: true)
    }
    
    func onMessageAdded(_ message: MockMessage) {
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
            self.firebaseManager.setReadMessage(curUser, otherUser, message)
        } else {
            self.firebaseManager.observeMessageStatus(curUser, otherUser, message)
        }
    }
    
    func onSelfStateChanged(_ state: UserContact) {
        return
    }
    
    func onUserAdded(_ user: UserContact) {
        return
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
    
    var curUser: MockUser!
    var otherUser: MockUser!
    
    var isTyping: Bool = false
    
    var firebaseManager: FirebaseManager = FirebaseManager()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    
        configureMessageCollectionView()
        configureMessageInputBar()
        
        self.addTitle(title: otherUserDisplayName)
        self.curUser = MockUser(senderId: externalID, displayName: userEntity?.displayName ?? "")
        self.otherUser = MockUser(senderId: otherUserID, displayName: otherUserDisplayName)
        
        firebaseManager.delegate = self
        firebaseManager.observeMessageAdded(curUser, otherUser)
        firebaseManager.observeTypingStatus(otherUser.senderId)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        firebaseManager.delegate = nil
        self.messageInputBar.inputTextView.endEditing(true)
        
        super.viewWillDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false

        showMessageTimestampOnSwipeLeft = true // default false
        
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .primaryColor
        messageInputBar.sendButton.setTitleColor(.primaryColor, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.primaryColor.withAlphaComponent(0.3),
            for: .highlighted
        )
    }
    
    // MARK: - Helpers
    
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
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }

    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
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
    
}

// MARK: - MessageCellDelegate

extension BaseChatViewController: MessageCellDelegate {
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

extension BaseChatViewController: MessageLabelDelegate {
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

extension BaseChatViewController: InputBarAccessoryViewDelegate {

    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        firebaseManager.setUserTyping(curUser.senderId)
        if !isTyping {
            let data = [
                "senderId": self.externalID,
                "isAnon": !self.otherUserID.hasPrefix(AnnoymousIdPrefix)
            ] as [String : Any]
            self.firebaseManager.sendPushNotification(otherUserPushToken, String(format: TypingMessageFormat, self.curUser.displayName), "", data)
            isTyping = true
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
        inputBar.inputTextView.resignFirstResponder()
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
                let message = ["sender_id": curUser.senderId, "type": "text", "message": str, "date": getCurrentUtcTimeInterval()] as [String : Any]
                self.firebaseManager.sendMessage(curUser, otherUser, message, otherUserPushToken, curUser.displayName)
                
                incrementScore(senderID: externalID, recieiverID: otherUserID)
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
                            self.firebaseManager.sendImage(self.curUser, self.otherUser, image!, self.otherUserPushToken, self.curUser.displayName)
                            isSent = true
                        }
                    }
                }
            } else {
                PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { (asset, audioMix, info) in
                    if let asset = asset as? AVURLAsset, let data = NSData(contentsOf: asset.url) {
                        let extension_str = asset.url.absoluteString.components(separatedBy: ".").last ?? "MOV"
                        self.getThumbnailImageFromVideoUrl(url: asset.url) { (thumb) in
                            if thumb != nil {
                                if !isSent {
                                    self.firebaseManager.sendVideo(self.curUser, self.otherUser, data as Data, extension_str, thumb!, self.otherUserPushToken, self.curUser.displayName)
                                    isSent = true
                                }
                            }
                        }
                    }
                }
            }
        }, completion: {
            print("select image completed")
        })
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

