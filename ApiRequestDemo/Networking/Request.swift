//
//  Request.swift
//  GoodJob
//
//  Created by Johnson on 2017/7/28.
//  Copyright © 2017年 Johnson. All rights reserved.
//

import RxSwift
import UIKit
import Photos

@objc class Request: NSObject {
    
    @objc static var shared = Request()
    
    private var requestingUrl = Set<String>()
    
    func api(from api: ApiKey, parameter: [String: Any]? = nil, isConcurrency: Bool = false) -> Observable<ResponseState<NSDictionary>> {
        return Observable.create { (observer) -> Disposable in
            var urlString = "https://test.xl18api09.com" + "/" + api.apiVersion
            
            for i in 0..<api.keys.count {
                if !api.keys[i].isEmpty {
                    urlString.append("/\(api.keys[i])")
                }
                if api.parametersForKeys.count > i {
                    if let key = api.parametersForKeys[i] {
                        urlString.append("/\(key)")
                    }
                }
            }
            
            if self.requestingUrl.contains(urlString) {
                print("break")
            } else {
                if isConcurrency {
                    self.requestingUrl.insert(urlString)
                }
                
                debugPrint("[\(api.httpMethod.rawValue)] \(urlString)", terminator: "\n")
                debugPrint(parameter?.description ?? "no parameters", terminator: "\n")
                Networking.request(from: urlString, HTTPMethod: api.httpMethod, contentType: api.contentType, parameter: parameter) { (data, response, url, error) in
                    self.requestingUrl.remove(urlString)
                    observer.onNext(self.handleResponseDictionary(with: (data, response, url, error)))
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
        
    }
    
    func api<T: Decodable>(from api: ApiKey, parameter: [String: Any]? = nil, model: T.Type, isConcurrency: Bool = false) -> Observable<ResponseState<T>> {
        return Observable.create { (observer) -> Disposable in
            var urlString = "https://test.xl18api09.com" + "/" + api.apiVersion
            
            for i in 0..<api.keys.count {
                urlString.append("/\(api.keys[i])")
                if api.parametersForKeys.count > i {
                    if let key = api.parametersForKeys[i] {
                        urlString.append("/\(key)")
                    }
                }
            }
            
            if self.requestingUrl.contains(urlString) {
                debugPrint("break")
            } else {
                if isConcurrency {
                    self.requestingUrl.insert(urlString)
                }
                
                Networking.request(from: urlString, HTTPMethod: api.httpMethod, contentType: api.contentType, parameter: parameter) { (data, response, url, error) in
                    self.requestingUrl.remove(urlString)
                    observer.onNext(self.handleResponse(with: (data, response, url, error), model: model, completionHandler: nil))
                    observer.onCompleted()
                }
            }
            return Disposables.create {
                
            }
        }
    }
    
    private struct JsonDecode<T: Decodable>: Decodable {
        var data: T
    }
    
    private func handleResponse<T: Decodable>(with responseContent: responseContent, model: T.Type, completionHandler: ResultCompletionHandler<T>?) -> ResponseState<T> {
        
        guard responseContent.error == nil else {
            if let error = responseContent.error as? URLError {
                if error.code == .notConnectedToInternet {
                    completionHandler?(ResponseState.failure(NetworkingError.noNetworkingConnect))
                    return ResponseState.failure(NetworkingError.noNetworkingConnect)
                }
            }
            completionHandler?(ResponseState.failure(NetworkingError.error(responseContent.error!)))
            return ResponseState.failure(NetworkingError.error(responseContent.error!))
        }
        guard let response = responseContent.response, let data = responseContent.data else {
            completionHandler?(ResponseState.failure(NetworkingError.responseAndDataNil))
            return ResponseState.failure(NetworkingError.responseAndDataNil)
        }
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            completionHandler?(ResponseState.failure(NetworkingError.statusCodeError(0, nil)))
            return ResponseState.failure(NetworkingError.responseAndDataNil)
        }
        
        guard statusCode != 400  else {
            let dataModel = try? JSONDecoder().decode(MessageResult.self, from: data)
            completionHandler?(ResponseState.failure(NetworkingError.statusCodeError(400, dataModel)))
            return ResponseState.failure(NetworkingError.statusCodeError(400, dataModel))
        }
        
        guard 200...299 ~= statusCode else {
            let modelDecode = try? JSONDecoder().decode(MessageResult.self, from: data)
            completionHandler?(ResponseState.failure(NetworkingError.statusCodeError((response as! HTTPURLResponse).statusCode, modelDecode)))
            return ResponseState.failure(NetworkingError.statusCodeError((response as! HTTPURLResponse).statusCode, modelDecode))
        }
        
        //success part
        var dataDecode: JsonDecode<T>?
        if let jsonDecode = try? JSONDecoder().decode(JsonDecode<T>.self, from: data) {
            dataDecode = jsonDecode
        }
        
        if dataDecode == nil {
            if let modelDecode = try? JSONDecoder().decode(T.self, from: data) {
                dataDecode = JsonDecode(data: modelDecode)
            }
        }
        
        guard dataDecode != nil else {
            completionHandler?(ResponseState.failure(NetworkingError.jsonParseFail))
            debugPrint("\(model.self) \(NetworkingError.jsonParseFail.rawValue)")
            return ResponseState.failure(NetworkingError.jsonParseFail)
        }
        
        completionHandler?(ResponseState.success(dataDecode!.data))
        return ResponseState.success(dataDecode!.data)
    }
    
    // MARK: - Return NSDictionary
    private func handleResponseDictionary(with responseContent: responseContent) -> ResponseState<NSDictionary> {
        
        guard responseContent.error == nil else {
            if let error = responseContent.error as? URLError {
                if error.code == .notConnectedToInternet {
                    return ResponseState.failure(NetworkingError.noNetworkingConnect)
                }
            }
            
            return ResponseState.failure(NetworkingError.error(responseContent.error!))
        }
        guard let response = responseContent.response, let data = responseContent.data else {
            return ResponseState.failure(NetworkingError.responseAndDataNil)
        }
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            return ResponseState.failure(NetworkingError.responseAndDataNil)
        }
        
        guard statusCode != 400  else {
            let dataModel = try? JSONDecoder().decode(MessageResult.self, from: data)
            return ResponseState.failure(NetworkingError.statusCodeError(400, dataModel))
        }
        
        guard 200...299 ~= statusCode else {
            let modelDecode = try? JSONDecoder().decode(MessageResult.self, from: data)
            return ResponseState.failure(NetworkingError.statusCodeError((response as! HTTPURLResponse).statusCode, modelDecode))
        }
        
        guard 200...299 ~= statusCode else {
            let modelDecode = try? JSONDecoder().decode(MessageResult.self, from: data)
            return ResponseState.failure(NetworkingError.statusCodeError((response as! HTTPURLResponse).statusCode, modelDecode))
        }
        
        //success part
        if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
            return ResponseState.success(dict)
        } else {
            return ResponseState.failure(.jsonParseFail)
        }
    }
}
