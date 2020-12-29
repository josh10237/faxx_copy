//
//  SocketIOManager.swift
//  Faxx
//
//  Created by Raul Cheng on 12/27/20.
//

import UIKit
import SocketIO
import SwiftyJSON

protocol SocketIOManagerDelegate {
    func contactCreated(result: JSON)
    func messageReceived(result: JSON)
    func lastMessageUpdated(result: JSON)
    func readMessage(result: JSON)
    func readAllMessage(result: JSON)
    func userTyping(result: JSON)
}

class SocketIOManager: NSObject {
    
    let SocketUrl = NetworkManager.shared.BaseUrl
    
    let SocketEmitCreateContact = "create_contact"
    let SocketOnContactCreated = "contact_created"
    let SocketEmitSendMessage = "send_msg"
    let SocketOnReceiveMessage = "receive_msg"
    let SocketEmitReadMessage = "read_msg"
    let SocketOnReadMessage = "read_msg"
    let SocketEmitReadAllMessage = "read_all_msg"
    let SocketOnReadAllMessage = "read_all_msg"
    let SocketOnLastMessageUpdated = "update_last_msg"
    let SocketEmitUserTyping = "user_typing"
    let SocketOnUserTyping = "user_typing"
     
    var delegate: SocketIOManagerDelegate?
    var sender_id = ""
    var receiver_id = ""
    
    var userId: Int = 0
    
    static let shared = SocketIOManager()
    
    // MARK: - Init socket
    
    var socketManager: SocketManager!
    
    override init() {
        super.init()
        
    }
    
    func establishConnection(user_id: Int) {
        userId = user_id
        socketManager = SocketManager(socketURL: URL(string: SocketUrl)!, config: [.log(true), .connectParams(["userId": userId])])
        
        socketManager.defaultSocket.connect()
        socketHandler()
    }
      
    func socketHandler() {
        //  DispatchQueue.main.asyncAfter(deadline: .now() + 8.0, execute: {
        self.socketManager.defaultSocket.onAny {
            let evt = "\($0.event)"
            print("event: ", evt)
            if evt.uppercased() == "ERROR" {
                self.socketManager.defaultSocket.connect(timeoutAfter: 1) {
                    print("Reconnected")
                }
            }
        }
        
        socketManager.defaultSocket.on(clientEvent: .connect) {data, ack in
            print("socket connected-----Connect to server", data)
            //print("kAppDelegate.dictUserInfo!-----\(kAppDelegate.dictUserInfo!)")
        }
        self.onCreatedContact()
        self.onReceiveMessage()
        self.onReadMessage()
        self.onReadAllMessage()
        self.onLastMessageUpdated()
        self.onUserTyping()
    }
    
    // MARK: - Chat Socket
    
    func createContact(params: [String : Any]) {
        socketManager.defaultSocket.emit(SocketEmitCreateContact, with: [params])
    }
    
    func onCreatedContact() {
        socketManager.defaultSocket.on(SocketOnContactCreated) { (result, socketAckEmitter) in
            let jsonData = JSON(result)
            self.delegate?.contactCreated(result: jsonData)
        }
    }
    
    func sendMessage(params: [String : Any]) {
        socketManager.defaultSocket.emit(SocketEmitSendMessage, with: [params])
    }
    
    func onReceiveMessage() {
        socketManager.defaultSocket.on(SocketOnReceiveMessage) { (result, socketAckEmitter) in
            let jsonData = JSON(result)
            self.delegate?.messageReceived(result: jsonData)
        }
    }
    
    func onLastMessageUpdated() {
        socketManager.defaultSocket.on(SocketOnLastMessageUpdated) { (result, socketAckEmitter) in
            let jsonData = JSON(result)
            self.delegate?.lastMessageUpdated(result: jsonData)
        }
    }
    
    func readAllMessage(params: [String : Any]) {
        socketManager.defaultSocket.emit(SocketEmitReadAllMessage, with: [params])
    }
    
    func onReadAllMessage() {
        socketManager.defaultSocket.on(SocketOnReadAllMessage) { (result, socketAckEmitter) in
            let jsonData = JSON(result)
            self.delegate?.readAllMessage(result: jsonData)
        }
    }
    
    func readMessage(params: [String : Any]) {
        socketManager.defaultSocket.emit(SocketEmitReadMessage, with: [params])
    }
    
    func onReadMessage() {
        socketManager.defaultSocket.on(SocketOnReadMessage) { (result, socketAckEmitter) in
            let jsonData = JSON(result)
            self.delegate?.readMessage(result: jsonData)
        }
    }
    
    func userTyping(params: [String : Any]) {
        socketManager.defaultSocket.emit(SocketEmitUserTyping, with: [params])
    }
    
    func onUserTyping() {
        socketManager.defaultSocket.on(SocketOnUserTyping) { (result, socketAckEmitter) in
            let jsonData = JSON(result)
            self.delegate?.userTyping(result: jsonData)
        }
    }
   
    // MARK: - Close Socket
    func closeConnection() {
        socketManager.defaultSocket.disconnect()
    }
      
    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
}


