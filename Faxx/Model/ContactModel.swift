//
//  ContactModel.swift
//  Faxx
//
//  Created by Raul Cheng on 12/23/20.
//

import Foundation
import SwiftyJSON

class ContactModel: NSObject {
    
    var id: Int = 0
    var f_id: Int = 0
    var f_display_name: String = ""
    var f_avatar: String = ""
    var f_fcm_token: String = ""
    var f_anon_display_name: String = ""
    var f_anon_avatar: String = ""
    var t_id: Int = 0
    var t_display_name: String = ""
    var t_avatar: String = ""
    var t_fcm_token: String = ""
    var t_anon_display_name: String = ""
    var t_anon_avatar: String = ""

    var last_msg_id: Int = 0

    var last_msg_sender_id: Int = 0
    var last_msg_type: String = ""
    var last_msg: String = ""
    var last_msg_status: String = "read"
    var last_msg_timestamp: Double = 0
    var d_start_msg_id: Int = 0
    var d_last_msg_id: Int = 0
    var anon_id: Int = 0
    var amIAnon: Bool = false
    var areTheyAnon: Bool = false
    var isTyping: Bool = false
    
    override init() {
        super.init()
    }
    
    init(_ contact: JSON, _ curUser: UserContact) {
        id = contact["id"].intValue
        f_id = contact["f_id"].intValue
        print(f_id, curUser.id)
        if (f_id == curUser.id) {
            f_display_name = contact["f_display_name"].stringValue
            f_avatar = contact["f_avatar"].stringValue
            f_fcm_token = contact["f_fcm_token"].stringValue
            f_anon_display_name = contact["f_anon_display_name"].stringValue
            f_anon_avatar = contact["f_anon_avatar"].stringValue
            t_id = contact["t_id"].intValue
            t_display_name = contact["t_display_name"].stringValue
            t_avatar = contact["t_avatar"].stringValue
            t_fcm_token = contact["t_fcm_token"].stringValue
            t_anon_display_name = contact["t_anon_display_name"].stringValue
            t_anon_avatar = contact["t_anon_avatar"].stringValue
        } else {
            t_id = contact["f_id"].intValue
            t_display_name = contact["f_display_name"].stringValue
            t_avatar = contact["f_avatar"].stringValue
            t_fcm_token = contact["f_fcm_token"].stringValue
            t_anon_display_name = contact["f_anon_display_name"].stringValue
            t_anon_avatar = contact["f_anon_avatar"].stringValue
            f_id = contact["t_id"].intValue
            f_display_name = contact["t_display_name"].stringValue
            f_avatar = contact["t_avatar"].stringValue
            f_fcm_token = contact["t_fcm_token"].stringValue
            f_anon_display_name = contact["t_anon_display_name"].stringValue
            f_anon_avatar = contact["t_anon_avatar"].stringValue
        }

        last_msg_id = contact["last_msg_id"].intValue

        last_msg_sender_id = contact["last_msg_sender_id"].intValue
        last_msg_type = contact["last_msg_type"].stringValue
        last_msg = contact["last_msg"].stringValue
        last_msg_status = contact["last_msg_status"].stringValue
        last_msg_timestamp = contact["last_msg_timestamp"].doubleValue
        d_start_msg_id = contact["d_start_msg_id"].intValue
        d_last_msg_id = contact["d_last_msg_id"].intValue
        anon_id = contact["anon_id"].intValue
        amIAnon = anon_id == curUser.id
        areTheyAnon = !amIAnon
    }
    
    func getJSON() -> [String : Any] {
        return [
            "id": id,
            "f_id": amIAnon ? f_id : t_id,
            "f_display_name": amIAnon ? f_display_name : t_display_name,
            "f_avatar": amIAnon ? f_avatar : t_avatar,
            "f_fcm_token": amIAnon ? f_fcm_token : t_fcm_token,
            "f_anon_display_name": amIAnon ? f_anon_display_name : t_anon_display_name,
            "f_anon_avatar": amIAnon ? f_anon_avatar : t_anon_avatar,
            "t_id": amIAnon ? t_id : f_id,
            "t_display_name": amIAnon ? t_display_name : f_display_name,
            "t_avatar": amIAnon ? t_avatar : f_avatar,
            "t_fcm_token": amIAnon ? t_fcm_token : f_fcm_token,
            "t_anon_display_name": amIAnon ? t_anon_display_name : f_anon_display_name,
            "t_anon_avatar": amIAnon ? t_anon_avatar : f_anon_avatar,

            "last_msg_id": last_msg_id,

            "last_msg_sender_id": last_msg_sender_id,
            "last_msg_type": last_msg_type,
            "last_msg": last_msg,
            "last_msg_status": last_msg_status,
            "last_msg_timestamp": last_msg_timestamp,
            "d_start_msg_id": d_start_msg_id,
            "d_last_msg_id": d_last_msg_id,
            "anon_id": anon_id
        ]
    }
}
