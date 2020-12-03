//
//  MockMessage.swift
//  Faxx
//
//  Created by Raul Cheng on 11/15/20.
//

import Foundation
import UIKit
import CoreLocation
import MessageKit
import AVFoundation

private struct CoordinateItem: LocationItem {

    var location: CLLocation
    var size: CGSize

    init(location: CLLocation) {
        self.location = location
        self.size = CGSize(width: 240, height: 240)
    }

}

private struct ImageMediaItem: MediaItem {

    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize

    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }

    init(imageURL: URL) {
        self.url = imageURL
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage(imageLiteralResourceName: "image_message_placeholder")
    }
}

private struct MockAudiotem: AudioItem {

    var url: URL
    var size: CGSize
    var duration: Float

    init(url: URL) {
        self.url = url
        self.size = CGSize(width: 160, height: 35)
        // compute duration
        let audioAsset = AVURLAsset(url: url)
        self.duration = Float(CMTimeGetSeconds(audioAsset.duration))
    }

}

struct MockContactItem: ContactItem {
    
    var displayName: String
    var initials: String
    var phoneNumbers: [String]
    var emails: [String]
    
    init(name: String, initials: String, phoneNumbers: [String] = [], emails: [String] = []) {
        self.displayName = name
        self.initials = initials
        self.phoneNumbers = phoneNumbers
        self.emails = emails
    }
    
}

struct MockLinkItem: LinkItem {
    let text: String?
    let attributedText: NSAttributedString?
    let url: URL
    let title: String?
    let teaser: String
    let thumbnailImage: UIImage
}

internal struct MockMessage: MessageType {

    var messageId: String
    var sender: SenderType {
        return user
    }
    var kind_str : String
    var sentDate: Date
    var kind: MessageKind
    var unread: Bool
    var url: URL? = nil
    var thumbnail: URL?

    var user: MockUser

    private init(kind: MessageKind, kind_str: String, user: MockUser, messageId: String, date: Date, unread: Bool) {
        self.kind = kind
        self.user = user
        self.messageId = messageId
        self.sentDate = date
        self.unread = unread
        self.kind_str = kind_str
    }
    
    init(custom: Any?, user: MockUser, messageId: String, date: Date, unread: Bool) {
        self.init(kind: .custom(custom), kind_str: "custom", user: user, messageId: messageId, date: date, unread: unread)
    }

    init(text: String, user: MockUser, messageId: String, date: Date, unread: Bool) {
        self.init(kind: .text(text), kind_str: "text", user: user, messageId: messageId, date: date, unread: unread)
    }
    
    init(attributedText: NSAttributedString, user: MockUser, messageId: String, date: Date, unread: Bool) {
        self.init(kind: .attributedText(attributedText), kind_str: "text", user: user, messageId: messageId, date: date, unread: unread)
    }

    init(image: UIImage, user: MockUser, messageId: String, date: Date, unread: Bool) {
        let mediaItem = ImageMediaItem(image: image)
        self.init(kind: .photo(mediaItem), kind_str: "photo", user: user, messageId: messageId, date: date, unread: unread)
    }

    init(imageURL: URL, user: MockUser, messageId: String, date: Date, unread: Bool) {
        let mediaItem = ImageMediaItem(imageURL: imageURL)
        self.init(kind: .photo(mediaItem), kind_str: "photo", user: user, messageId: messageId, date: date, unread: unread)
        url = imageURL
    }

    init(thumbnail: UIImage, user: MockUser, messageId: String, date: Date, unread: Bool) {
        let mediaItem = ImageMediaItem(image: thumbnail)
        self.init(kind: .video(mediaItem), kind_str: "video", user: user, messageId: messageId, date: date, unread: unread)
    }
    
    init(thumbnailURL: URL, videoURL : URL, user: MockUser, messageId: String, date: Date, unread: Bool) {
        let image = UIImage.load(from: thumbnailURL.absoluteString) ?? UIImage()
        let mediaItem = ImageMediaItem(image: image)
        self.init(kind: .video(mediaItem), kind_str: "video", user: user, messageId: messageId, date: date, unread: unread)
        thumbnail = thumbnailURL
        url = videoURL
    }

    init(location: CLLocation, user: MockUser, messageId: String, date: Date, unread: Bool) {
        let locationItem = CoordinateItem(location: location)
        self.init(kind: .location(locationItem), kind_str: "location", user: user, messageId: messageId, date: date, unread: unread)
    }

    init(emoji: String, user: MockUser, messageId: String, date: Date, unread: Bool) {
        self.init(kind: .emoji(emoji), kind_str: "emoji", user: user, messageId: messageId, date: date, unread: unread)
    }

    init(audioURL: URL, user: MockUser, messageId: String, date: Date, unread: Bool) {
        let audioItem = MockAudiotem(url: audioURL)
        self.init(kind: .audio(audioItem), kind_str: "audio", user: user, messageId: messageId, date: date, unread: unread)
    }

    init(contact: MockContactItem, user: MockUser, messageId: String, date: Date, unread: Bool) {
        self.init(kind: .contact(contact), kind_str: "contact", user: user, messageId: messageId, date: date, unread: unread)
    }

    init(linkItem: LinkItem, user: MockUser, messageId: String, date: Date, unread: Bool) {
        self.init(kind: .linkPreview(linkItem), kind_str: "link", user: user, messageId: messageId, date: date, unread: unread)
    }
}

