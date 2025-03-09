//
//  HTTPable.swift
//  httpable
//
//  Created by Mohammed Tabech on 2025-03-09.
//
import Combine

public struct HTTPConfig {
    var baseURL: String
}

public final class HTTPable {
    static var url = ""
    static var cancellables = Set<AnyCancellable>()
    
    public init() {}
    
    public static func configure(_ config: HTTPConfig) {
        self.url = config.baseURL
    }
}
