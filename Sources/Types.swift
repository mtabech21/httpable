

import Foundation
import Combine


public enum APIPath {
    case to(String),
         param(key: String)
}

public struct Query {
    var key: String
    var value: String
    public init(key: String,_ value: String) {
        self.key = key
        self.value = value
    }
}

public struct Param {
    var key: String
    var value: String
    public init(key: String,_ value: String) {
        self.key = key
        self.value = value
    }
}

public struct Req<B: Codable> {
    public var params: [Param] = []
    public var query: [Query] = []
    public var body: B? = nil

    func GenerateURL(url_path: String) -> URL? {
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
        let full = "\(HTTPable.url)\(newPath)"
        return URL(string: full.replacingOccurrences(of: " ", with: ""))
    }
}
public struct Res<B> {
    public var response: HTTPURLResponse?
    public var body: B?
    public var error: Error?
}


public struct Bodyless: Codable {}



