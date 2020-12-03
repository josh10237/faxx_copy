//
//  Global.swift
//  Faxx
//
//  Created by Raul Cheng on 11/11/20.
//

import Foundation
import UIKit

let AnnoymousIdPrefix = "ZAAAAA3AAAAAZ"
let DefaultAvatarUrl = "https://static.thenounproject.com/png/630729-200.png"

var FCM_Token = ""

var TypingMessageFormat = "%@ is typing..."
var SentMessageFormat = "%@ Sent %@"

func getCurrentUtcTimeInterval() -> Double {
    let utcDateFormatter = DateFormatter()
    utcDateFormatter.dateStyle = .medium
    utcDateFormatter.timeStyle = .medium
    utcDateFormatter.timeZone = TimeZone(abbreviation: "UTC")

    let date = Date()
    let dateString = utcDateFormatter.string(from: date)
    let utcDate = utcDateFormatter.date(from: dateString)
    
    return utcDate?.timeIntervalSince1970 ?? date.timeIntervalSince1970
}

func getExtenalId(_ id: String) -> String {
    return String(id.dropFirst(6).replacingOccurrences(of: "/", with: ""))
}

var UserGender: String? {
    get {
        return UserDefaults.standard.string(forKey: "USER_GENDER")
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "USER_GENDER")
    }
}

var AnnonImageName: String? {
    get {
        return UserDefaults.standard.string(forKey: "ANNON_IMAGE_NAME")
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "ANNON_IMAGE_NAME")
    }
}

let AvatarList: [String] = [
    "Acorn",
    "Banana",
    "Baseball",
    "Bonfire",
    "Boots",
    "Bowling-Ball",
    "Cake",
    "Camera",
    "Carrot",
    "Cat",
    "Cheese",
    "Coffee",
    "Dog",
    "Dynamite",
    "Eiffel-Tower",
    "Fish",
    "Giraffe",
    "Glasses",
    "Grapes",
    "Guitar",
    "Hand",
    "Harmonica",
    "Hippo",
    "Hot-Air-Balloon",
    "Hotdog",
    "Juicebox",
    "Magic-Wand",
    "Maple-Leaf",
    "Money-Bag",
    "Motorcycle",
    "Muffin",
    "Palm",
    "Parachutist",
    "Peach",
    "Pizza",
    "Pumpkin",
    "Racecar",
    "Rocket-Ship",
    "Santa-Claus",
    "Skateboard",
    "Skyscraper",
    "Teapot",
    "Teddy-Bear",
    "Tennis-Racket",
    "Toilet_Paper",
    "Tractor",
    "Traffic-Cone",
    "Tv",
    "Umbrella",
    "Wheel"
]

func getRandomAvatar(_ gender: String) -> String {
    var avatar = ""
    if (AnnonImageName ?? "") == "" {
        let random: String = AvatarList.randomElement() ?? ""
        avatar = "\(random)_\(gender)"
        AnnonImageName = avatar
    } else {
        avatar = AnnonImageName ?? ""
    }
    return avatar
}
