//
//  Api.swift
//  ECS189E
//
//  Created by Zhiyi Xu on 9/23/18.
//  Copyright © 2018 Sam King. All rights reserved.
//

import Foundation

struct Api {
    
    struct ApiError: Error {
        var message: String
        var code: String
        
        init(response: [String: Any]) {
            self.message = (response["error_message"] as? String) ?? "Network error"
            self.code = (response["error_code"] as? String) ?? "network_error"
        }
    }
    
    typealias ApiCompletion = ((_ response: [String: Any]?, _ error: ApiError?) -> Void)
    
    static var baseUrl = "https://ecs189e-fall2018.appspot.com/api"
    static let defaultError = ApiError(response: [:])
    
    static func configuration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        if let authToken = Storage.authToken {
            config.httpAdditionalHeaders = ["x-authtoken": authToken]
            print("auth in config:\(authToken)")
        } else {
            config.httpAdditionalHeaders = [:]
        }
        return config
    }
    
    static func ApiCall(endpoint: String, parameters: [String: Any], completion: @escaping ApiCompletion) {
        guard let url = URL(string: baseUrl + endpoint) else {
            print("Wrong url")
            return
        }
        
        let session = URLSession(configuration: configuration())
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let requestData = try? JSONSerialization.data(withJSONObject: parameters) else {
            DispatchQueue.main.async { completion(nil, defaultError) }
            return
        }
        
        session.uploadTask(with: request, from: requestData) { data, response, error in
            guard let rawData = data else {
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            let jsonData = try? JSONSerialization.jsonObject(with: rawData)
            guard let responseData = jsonData as? [String: Any] else {
                DispatchQueue.main.async { completion(nil, defaultError) }
                return
            }
            
            DispatchQueue.main.async {
                if "ok" == responseData["status"] as? String {
                    completion(responseData, nil)
                } else {
                    completion(nil, ApiError(response: responseData))
                }
            }
            }.resume()
    }
    
    static func sendVerificationCode(phoneNumber: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/send_verification_code",
                parameters: ["phone_number": phoneNumber],
                completion: completion)
    }
    
    static func verifyCode(phoneNumber: String, code: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/verify_code",
                parameters: ["e164_phone_number": phoneNumber, "code": code],
                completion: completion)
    }
    
    
    static func setName(name: String, completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/user",
                parameters: ["name": name],
                completion: completion)
    }
    
    static func setAccounts(accounts: [Account], completion: @escaping ApiCompletion) {
        let serverAccounts = accounts.map { ["name": $0.name, "ID": $0.ID, "amount": String($0.amount)] }
        ApiCall(endpoint: "/user",
                parameters: ["accounts": serverAccounts],
                completion: completion)
    }
    
    static func user(completion: @escaping ApiCompletion) {
        ApiCall(endpoint: "/user",
                parameters: [:],
                completion: completion)
    }
    
    static func deposit(wallet: Wallet, toAccountAt accountIndex: Int, amount: Double, completion: @escaping ApiCompletion) {
        wallet.accounts[accountIndex].amount += amount
        wallet.totalAmount += amount
        let serverAccounts = wallet.accounts.map { ["name": $0.name, "ID": $0.ID, "amount": String($0.amount)] }
        ApiCall(endpoint: "/user",
                parameters: ["accounts": serverAccounts],
                completion: completion)
    }
    static func withdraw(wallet: Wallet, fromAccountAt accountIndex: Int, amount: Double, completion: @escaping ApiCompletion) {
        wallet.accounts[accountIndex].amount -= amount
        wallet.totalAmount -= amount
        let serverAccounts = wallet.accounts.map { ["name": $0.name, "ID": $0.ID, "amount": String($0.amount)] }
        ApiCall(endpoint: "/user",
                parameters: ["accounts": serverAccounts],
                completion: completion)
    }
    static func transfer(wallet: Wallet, fromAccountAt fromIndex: Int, toAccountAt toIndex: Int, amount: Double, completion: @escaping ApiCompletion) {
        wallet.accounts[fromIndex].amount -= amount
        wallet.accounts[toIndex].amount += amount
        let serverAccounts = wallet.accounts.map { ["name": $0.name, "ID": $0.ID, "amount": String($0.amount)] }
        ApiCall(endpoint: "/user",
                parameters: ["accounts": serverAccounts],
                completion: completion)
    }
    
    static func addNewAccount(wallet: Wallet, newAccountName name: String, completion: @escaping ApiCompletion) {
        let newAccount = Account.init(name: name)
        wallet.accounts.append(newAccount)
        let serverAccounts = wallet.accounts.map { ["name": $0.name, "ID": $0.ID, "amount": String($0.amount)] }
        ApiCall(endpoint: "/user",
                parameters: ["accounts": serverAccounts],
                completion: completion)
    }
    static func removeAccount(wallet: Wallet, removeAccountat index: Int, completion: @escaping ApiCompletion) {
        wallet.totalAmount -= wallet.accounts[index].amount
        wallet.accounts.remove(at: index)
        let serverAccounts = wallet.accounts.map { ["name": $0.name, "ID": $0.ID, "amount": String($0.amount)] }
        ApiCall(endpoint: "/user",
                parameters: ["accounts": serverAccounts],
                completion: completion)
    }
}
