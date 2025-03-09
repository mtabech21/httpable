//
//  Gettable.swift
//  httpable
//
//  Created by Mohammed Tabech on 2025-03-09.
//
import Combine
import Foundation

public class Gettable<ResultBody: Codable> {
    private var url_path: String
    public let request = Req<Bodyless>()
    public init(_ path: [APIPath]) {
        var url_path = ""
        for p in path {
            switch p {
            case .to(let string):
                url_path.append("/\(string)")
            case .param(let string):
                url_path.append("/<P=\(string)>")
            }
        }
        self.url_path = url_path
    }
    
    public func get<RequestBody: Codable>(with request: Req<RequestBody>,_ handler: @escaping (Res<ResultBody>) -> Void) {
        var res = Res<ResultBody>()
        guard let url = request.GenerateURL(url_path: url_path) else  {  res.error = URLError(.badURL); return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        
        URLSession.shared.dataTaskPublisher(for: req)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .tryMap { (data, response) -> Data in
                print(response)
                guard let response = response as? HTTPURLResponse,
                        response.statusCode >= 200 && response.statusCode < 300 else {
                    res.error = URLError(.badServerResponse)
                    handler(res)
                    throw URLError(.badServerResponse)
                }
                res.response = response
                return data
            }
            .decode(type: ResultBody.self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case.finished:
                    break
                case.failure(let err):
                    res.error = err
                    handler(res)
                }
            } receiveValue: { fetched in
                res.body = fetched
                handler(res)
            }
            .store(in: &HTTPable.cancellables)
    }
}
