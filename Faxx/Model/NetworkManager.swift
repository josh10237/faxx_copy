//
//  NetworkManager.swift
//  Faxx
//
//  Created by Raul Cheng on 12/23/20.
//

import Foundation
import Alamofire
import SwiftyJSON

class NetworkManager: NSObject {
    
    static let shared = NetworkManager()
    
    // MARK: - URL
    
//    let BaseUrl = "http://192.168.0.65:6001"
    let BaseUrl = "http://162.0.239.44:6001"
    var AddUser = ""
    var UpdateUser = ""
    var AllContacts = ""
    var CreateContact = ""
    var AllMessages = ""
    var UploadChatImage = ""
    
    
    // MARK: - Life Cycle
    
    override init() {
        super.init()
        
        AddUser = "\(BaseUrl)/user/add"
        UpdateUser = "\(BaseUrl)/user/update"
        AllContacts = "\(BaseUrl)/chat/all-contacts"
        CreateContact = "\(BaseUrl)/chat/create-contact"
        AllMessages = "\(BaseUrl)/chat/all-messages"
        UploadChatImage = "\(BaseUrl)/chat/upload-image"
    }
    
    // MARK: - Request Functions
    
    func getRequest(url: URL, headers: HTTPHeaders?, completion: @escaping (JSON)->Void) {
        AF.request(url, method: .get, headers: headers).responseJSON { (response) in
            if let result = response.value {
                let jsonData = JSON(result)
                completion(jsonData)
            } else {
                completion(JSON([
                    "res": "failed",
                    "err_msg": "Connection failed.",
                ]))
            }
        }
    }

    func postRequest(url: URL, headers: HTTPHeaders?, params: Parameters, completion: @escaping (JSON)->Void) {
        AF.request(url, method: .post, parameters: params, headers: headers).responseJSON { (response) in
            if let result = response.value {
                let jsonData = JSON(result)
                completion(jsonData)
            } else {
                completion(JSON([
                    "res": "failed",
                    "err_msg": "Connection failed.",
                ]))
            }
        }
    }
    
    func uploadImage(image: UIImage, url: String, completion: @escaping (JSON)->Void) {
        let imgData = image.jpegData(compressionQuality: 0.7)!
        let file_name = "temp.jpg"
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imgData, withName: "image", fileName: file_name, mimeType: "image/jpg")
        }, to: url)
        .responseJSON { (response) in
            if let result = response.value {
                let jsonData = JSON(result)
                completion(jsonData)
            } else {
                completion(JSON([
                    "code": 405,
                    "data": [
                        "msg": "Connection failed.",
                    ]
                ]))
            }
        }
    }
    
    func isConnectedNetwork() -> Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
}
