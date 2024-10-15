

import Foundation
import Combine

class http {
    static var cancellables = Set<AnyCancellable>()
}


public enum APIPath {
    case to(String),
         param(key: String)
}

struct Query {
    var key: String
    var value: String
    init(key: String,_ value: String) {
        self.key = key
        self.value = value
    }
}
struct Param {
    var key: String
    var value: String
    init(key: String,_ value: String) {
        self.key = key
        self.value = value
    }
}

struct Req<B: Codable> {
    var params: [Param] = []
    var query: [Query] = []
    var body: B? = nil

    fileprivate func GenerateURL(url_path: String) -> URL? {
        var newPath = url_path
        for param in params {
            newPath = newPath.replacingOccurrences(of: "<P=\(param.key)>", with: "\(param.value)")
        }
        var queries: [String] = []
        newPath.append("?")
        for q in query {
            queries.append("\(q.key)=\(q.value)")
        }
        
        newPath.append(queries.joined(separator: "&"))
        let full = "https://bot.metesolutions.com\(newPath)"
        return URL(string: full.replacingOccurrences(of: " ", with: ""))
    }
}
struct Res<B> {
    var response: HTTPURLResponse?
    var body: B?
    var error: Error?
}


struct Bodyless: Codable {}

class Gettable<ResultBody: Codable> {
    private var url_path: String
    let request = Req<Bodyless>()
    init(_ path: [APIPath]) {
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
    
    func get<RequestBody: Codable>(with request: Req<RequestBody>,_ handler: @escaping (Res<ResultBody>) -> Void) {
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
            .store(in: &http.cancellables)
    }
}

struct Postable<RequestBody: Codable, ResultBody: Codable> {
    private var url_path: String
    let request = Req<RequestBody>()
    init(_ path: [APIPath]) {
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
    
    func post(with request: Req<RequestBody>,_ handler: @escaping (Res<ResultBody>) -> Void) {
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
                    .store(in: &http.cancellables)
            
        } catch let error {
            res.error = error
            handler(res)
        }
    }
}
