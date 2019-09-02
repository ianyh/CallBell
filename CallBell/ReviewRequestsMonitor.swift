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
    private let callback: (Bool) -> Void
    
    private var timer: Timer?
    private var dataTask: URLSessionDataTask?
    
    init(username: String, token: String, callback: @escaping (Bool) -> Void) {
        self.encodedAuth = "\(username):\(token)".data(using: .utf8)!.base64EncodedString()
        self.callback = { value in
            DispatchQueue.main.async {
                callback(value)
            }
        }
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
            
            guard let data = data else {
                callback(false)
                return
            }
            
            let decoder = JSONDecoder()
            
            guard let result = try? decoder.decode(RequestResult.self, from: data) else {
                callback(false)
                return
            }
            
            callback(result.totalCount > 0)
        }
        dataTask?.resume()
    }
}
