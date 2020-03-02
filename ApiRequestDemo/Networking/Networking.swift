//
//  API.swift
//  GoodJob
//
//  Created by Johnson on 2017/7/28.
//  Copyright © 2017年 Johnson. All rights reserved.
//

import UIKit
import RxSwift

enum ResponseState<T> {
    case success(T)
    case failure(NetworkingError) //all error message
}

///Networking Error
enum NetworkingError {
    
    case responseAndDataNil
    case urlDismatch
    case errorMessageJSONParseFail
    case jsonParseFail
    case error(Error)
    case noNetworkingConnect
    case othersError(String)
    case statusCodeError(Int, MessageResult?)
    
    var rawValue : String {
        switch self {
        case .responseAndDataNil: return "ERROR: Response or Data is nil"
        case .urlDismatch: return "ERROR: RequestURL and ResponseURL dismatch"
        case .errorMessageJSONParseFail: return "ERROR: Error Message JSON parse fail"
        case .jsonParseFail: return "ERROR: JSON parse fail"
        case .error(let error): return "ERROR: \(error.localizedDescription)"
        case .noNetworkingConnect: return "ERROR: No Networking connect"
        case .othersError(let message): return "ERROR: \(message)"
        case .statusCodeError(let code): return "ERROR: status code is \(code), not equal to 2XX"
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .statusCodeError(_, let messages): return messages?.message
        default: return nil
        }
    }
    
    var resultCode: Int {
        switch self {
        case .statusCodeError(_, let message): return message?.code ?? 0
        default: return 0
        }
    }
    
    var data: JSONValue? {
        switch self {
        case .statusCodeError(_, let messages): return messages?.data
        default: return nil
        }
    }
    
    var localizedDescription: String? {
        switch self {
        case .error(let error): return error.localizedDescription
        default: return nil
        }
    }
}

typealias ResultCompletionHandler<T: Decodable> = (ResponseState<T>)->()
typealias responseContent = (data: Data?, response:  URLResponse?, url: URL, error: Error?)

enum HTTPMethod: String {
    case delete = "DELETE"
    case post = "POST"
    case get = "GET"
    case put = "PUT"
    case patch = "PATCH"
}

enum ContentType: String {
    case json = "application/json"
    case formData = "multipart/form-data"
    case urlencoded = "application/x-www-form-urlencoded"
    case query = ""
}

@objc class Networking : NSObject {
    
    private static var appVersion: String {
        return (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    
    private static var bundleVersion: String {
        return (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
    }
    
    static func getRequest(from url: String, HTTPMethod: HTTPMethod = .get, contentType: ContentType = .query, parameter: [String: Any]? = nil, completion: ((NSDictionary?, Error?) -> Void)?) {
        Networking.request(from: url, HTTPMethod: HTTPMethod, contentType: contentType, parameter: parameter) { (data, response, url, error) in
            if error != nil {
                completion?(nil, error)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as! NSDictionary
                    completion?(json, nil)
                } catch {
                    completion?(nil, nil)
                }
            }
        }
    }
    
    static func request(from url: String, HTTPMethod: HTTPMethod, contentType: ContentType, parameter: [String: Any]?, completion: ((Data?, URLResponse?, URL, Error?) -> Void)?) {
        
        guard let requestUrl = URL(string: url) else { return }
        
        var request = URLRequest(url: requestUrl)
        request.timeoutInterval = 30
        
        if contentType != .formData {
            request.addValue(contentType.rawValue, forHTTPHeaderField:"Content-Type")
        }
        request.httpMethod = HTTPMethod.rawValue
        
        switch contentType {
        case .json:
            if let parameter = parameter {
                if let jsonData = try? JSONSerialization.data(withJSONObject: parameter){
                    
                    request.httpBody = jsonData
                }
            }
        case .formData:
            let boundary = "Boundary-\(NSUUID().uuidString)"
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:"Content-Type")
            
            if let parameter = parameter {
                var httpBoddy = Data()
                httpBoddy.append(parameter, boundary: boundary)
                httpBoddy.append("--\(boundary)--")
                request.httpBody = httpBoddy
            }
        case .urlencoded:
            if let parameter = parameter {
                
                var urlEncodedString = String()
                for parameter in parameter {
                    urlEncodedString = parameter.key + String(describing: parameter.value) + "&"
                }
                urlEncodedString.remove(at: urlEncodedString.index(before: urlEncodedString.endIndex))
                
                request.httpBody = urlEncodedString.data(using: .ascii, allowLossyConversion: false)
            }
        case .query:
            if let parameters = parameter {
                
                var component = URLComponents(string: url)
                var queryItems: [URLQueryItem] = []
                
                for parameter in parameters {
                    
                    if let array = parameter.value as? Array<Any> {
                        if array.isEmpty == false {
                            let array = array.map { value -> String in
                                let mi = Mirror(reflecting: value)
                                if mi.displayStyle != .optional {
                                    return String(describing: value)
                                } else {
                                    if mi.children.count != 0 {
                                        let (_, some) = mi.children.first!
                                        return String(describing: some)
                                    }
                                }
                                return ""
                            }
                            
                            var value = ""
                            array.forEach { value += $0 + "," }
                            value.remove(at: value.index(before: value.endIndex))
                            
                            let query = URLQueryItem(name: parameter.key, value: value)
                            queryItems.append(query)
                        }
                    } else {
                        var value: String = ""
                        
                        let mi = Mirror(reflecting: parameter.value)
                        if mi.displayStyle != .optional {
                            value = String(describing: parameter.value)
                        } else {
                            if mi.children.count != 0 {
                                let (_, some) = mi.children.first!
                                value = String(describing: some)
                            }
                        }

                        let query = URLQueryItem(name: parameter.key, value: value)
                        queryItems.append(query)
                    }
                }
                
                component?.queryItems = queryItems
                request.url = component?.url
            }
        }
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 30
        sessionConfiguration.timeoutIntervalForResource = 30
        let session = URLSession(configuration: sessionConfiguration)
        
        let task = session.dataTask(with: request) {(data, response, error) -> Void
            in
            completion?(data, response, requestUrl, error)
        }
        
        DispatchQueue.global().async {
            task.resume()
        }
    }
}

extension Networking {
    
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
    
    mutating func append(_ key: String, value: String, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
        append("\(value)\r\n")
    }
    
    mutating func append(_ parameter: Dictionary<String, Any>, boundary: String) {
        for (key, value) in parameter {
            if let image = value as? UIImage {
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    append("--\(boundary)\r\n")
                    append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key).jpg\"\r\n")
                    append("Content-Type: image/jpg\r\n\r\n")
                    append(imageData)
                    append("\r\n")
                }
            } else {
                append("--\(boundary)\r\n")
                append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                append("\(value)\r\n")
            }
        }
        
        print(String(data: self, encoding: .utf8) ?? "nothing")
    }
    
    mutating func append(_ fileUrl: URL, key: String, boundary: String) {
        let fileName = fileUrl.lastPathComponent
        let pathExtension = fileUrl.pathExtension
        do {
            let videoData = try Data(contentsOf: fileUrl, options: .alwaysMapped)
            
            append("\(boundary)")
            append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n")
            append("Content-Type: video/\(pathExtension)\r\n\r\n")
            append(videoData)
            append("\r\n")
        } catch {
            print("video url to data error")
        }
    }
    
    mutating func append(_ image: UIImage, name: String, filename: String, boundary: String) {
        if let data = image.jpegData(compressionQuality: 0.7) {
            
            append("\(boundary)")
            append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename).jpg\"\r\n")
            append("Content-Type: image/jpg\r\n\r\n")
            append(data)
            append("\r\n")
        }
    }
}

