//
//  Postable.swift
//  httpable
//
//  Created by Mohammed Tabech on 2025-03-09.
//
import Combine
import Foundation

public struct Postable<RequestBody: Codable, ResultBody: Codable> {
    private var url_path: String
    public let request = Req<RequestBody>()
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
    
    public func post(with request: Req<RequestBody>,_ handler: @escaping (Res<ResultBody>) -> Void) {
        var res = Res<ResultBody>()
        guard let url = request.GenerateURL(url_path: url_path) else  {  res.error = URLError(.badURL); return }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpMethod = "POST"
        let postData = request.body
        do {
            req.httpBody = try JSONEncoder().encode(postData)
            URLSession.shared.dataTaskPublisher(for: req)
                .tryMap { (data, response) -> Data in
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            throw URLError(.badServerResponse)
                        }
                        res.response = httpResponse
                        return data
                    }
                    .decode(type: ResultBody.self, decoder: JSONDecoder())
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print(error)
                            res.error = error
                        }
                    }, receiveValue: { response in
                        print(response)
                        res.body = response
                        handler(res)
                    })
                    .store(in: &HTTPable.cancellables)
            
        } catch let error {
            res.error = error
            handler(res)
        }
    }
}
