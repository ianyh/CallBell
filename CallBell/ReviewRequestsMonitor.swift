//
//  ReviewRequestsMonitor.swift
//  CallBell
//
//  Created by Ian Ynda-Hummel on 9/1/19.
//  Copyright © 2019 Ian Ynda-Hummel. All rights reserved.
//

import Foundation

private struct RequestResult: Decodable {
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
    }
}

class ReviewRequestsMonitor {
    private let encodedAuth: String
    private let callback: (Result<Bool, Error>) -> Void
    
    private var timer: Timer?
    private var dataTask: URLSessionDataTask?
    
    init(userData: UserData, callback: @escaping (Result<Bool, Error>) -> Void) {
        let decodedToken = String(data: userData.token, encoding: .utf8)!
        self.encodedAuth = "\(userData.username):\(decodedToken)".data(using: .utf8)!.base64EncodedString()
        self.callback = { result in
            DispatchQueue.main.async {
                callback(result)
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.check()
        }
        self.timer?.fire()
    }
    
    private func check() {
        var searchURLComponents = URLComponents()
        searchURLComponents.scheme = "https"
        searchURLComponents.host = "api.github.com"
        searchURLComponents.path = "/search/issues"
        searchURLComponents.queryItems = [URLQueryItem(name: "q", value: "is:open+is:pr+review-requested:ianyh")]
        
        var urlRequest = URLRequest(url: searchURLComponents.url!)
        urlRequest.addValue("Basic \(self.encodedAuth)", forHTTPHeaderField: "Authorization")
        
        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let callback = self?.callback else {
                return
            }
            
            let result = Result { () -> Bool in
                guard let data = data else {
                    return false
                }
                
                let decoder = JSONDecoder()
                
                guard let result = try? decoder.decode(RequestResult.self, from: data) else {
                    return false
                }
                
                return result.totalCount > 0
            }
            
            callback(result)
        }
        dataTask?.resume()
    }
}
