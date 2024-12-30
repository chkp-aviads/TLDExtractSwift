//
//  TLDExtract.swift
//  TLDExtract
//
//  Created by kojirof on 2018/11/16.
//  Copyright © 2018 Gumob. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 Extract root domain, top level domain (TLD), second level domain or subdomain from a hostname
 
 ```swift
 import TLDExtract

 let extractor = try! TLDExtract()
 let hostname: String = "www.ラーメン.寿司.co.jp"
 guard let result: TLDResult = extractor.parse(hostname) else { return }

 print(result.rootDomain)        // Optional("寿司.co.jp")
 print(result.topLevelDomain)    // Optional("co.jp")
 print(result.secondLevelDomain) // Optional("寿司")
 print(result.subDomain)         // Optional("www.ラーメン")
 ```
 
 This is possible thanks to a bundled version of the [Public Suffix List](https://publicsuffix.org/)

 You can also fetch the most up-to-date PSL with async function ``fetchLatestPSL()``
 
 ```swift
 try await extractor.fetchLatestPSL()
 ```
 */
public class TLDExtract {

    private var tldParser: TLDParser

    /// Initializes the extractor with information from the bundled Public Suffix List.
    public init() {
        let url = Bundle.module.url(forResource: "public_suffix_list", withExtension: "dat")!
        let data: Data = try! Data(contentsOf: url)
        let dataSet = try! PSLParser().parse(data: data)
        self.tldParser = TLDParser(dataSet: dataSet)
    }
    
    /// invoke network request to fetch latest [Public Suffix List](https://publicsuffix.org/list/public_suffix_list.dat) (PSL) from a remote server ensuring that extractor operates most accurate
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public func fetchLatestPSL() async throws {
        let url: URL = URL(string: "https://publicsuffix.org/list/public_suffix_list.dat")!
        let data: Data = try await withCheckedThrowingContinuation{ continuation in
            URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
                if let data = data {
                    continuation.resume(returning: data)
                } else if let error = error {
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
        let dataSet = try PSLParser().parse(data: data)
        self.tldParser = TLDParser(dataSet: dataSet)
    }

    /// Parse a hostname to extract top-level domain and other properties
    /// - Parameters:
    ///   - input: type conforming to `TLDExtractable`
    ///   - quick: option to speed up by parsing only normal data excluding exceptions and wildcards
    /// - Returns: optional `TLDResult`
    public func parse(_ input: TLDExtractable, quick: Bool = false) -> TLDResult? {
        guard let host: String = input.hostname else { return nil }
        if quick {
            return self.tldParser.parseNormals(host: host)
        } else {
            return self.tldParser.parseExceptionsAndWildcards(host: host) ??
                   self.tldParser.parseNormals(host: host)
        }
    }
    
    fileprivate static let schemeRegex: NSRegularExpression = {
        let schemePattern: String = "^(\\p{L}+:)?//"
        return try! NSRegularExpression(pattern: schemePattern)
    }()
    
    fileprivate static let hostRegex: NSRegularExpression = {
        let hostPattern: String = "([0-9\\p{L}][0-9\\p{L}-]{1,61}\\.?)?   ([\\p{L}-]*  [0-9\\p{L}]+)  (?!.*:$).*$".replace(" ", "")
        return try! NSRegularExpression(pattern: hostPattern)
    }()
}

/**
 Types conforming to this protocol can be parsed with ``TLDExtract/TLDExtract``.
 
 Swift Foundation types `URL` and `String` already conform to ``TLDExtractable``.
*/
public protocol TLDExtractable {
    var hostname: String? { get }
}

extension URL: TLDExtractable {

    init?(unicodeString: String) {
        if let encodedUrl: String = unicodeString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            self.init(string: encodedUrl)
        } else {
            self.init(string: unicodeString)
        }
    }

    public var hostname: String? {
        let result: String? = self.absoluteString.removingPercentEncoding?.hostname
        return result
    }
}

extension String: TLDExtractable {
    public var hostname: String? {
        if self.matches(TLDExtract.schemeRegex) {
            let components: [String] = self.replace(TLDExtract.schemeRegex, "").components(separatedBy: "/")
            guard let component: String = components.first, !component.isEmpty else { return nil }
            return component
        } else if self.matches(TLDExtract.hostRegex, options: .anchored) {
            let components: [String] = self.replace(TLDExtract.schemeRegex, "").components(separatedBy: "/")
            guard let component: String = components.first, !component.isEmpty else { return nil }
            return component
        } else {
            return URL(string: self)?.host
        }
    }
}

fileprivate extension String {
    func matches(_ pattern: String) -> Bool {
        guard let regex: NSRegularExpression = try? NSRegularExpression(pattern: pattern) else { return false }
        return matches(regex)
    }
    
    func matches(_ regex: NSRegularExpression, options: NSRegularExpression.MatchingOptions = []) -> Bool {
        return regex.matches(in: self, options: options, range: NSRange(location: 0, length: self.count)).count > 0
    }

    func replace(_ pattern: String, _ replacement: String) -> String {
        return self.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }
    
    func replace(_ regex: NSRegularExpression, _ replacement: String) -> String {
        // Define the range of the string to be searched
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        
        // Perform the replacement
        return regex.stringByReplacingMatches(
            in: self,
            options: [],
            range: range,
            withTemplate: replacement
        )
    }
}

/// Returning type of  the parsing method from ``TLDExtract/TLDExtract``  method for accessing top-level domain and other properties.
public struct TLDResult {
    public let rootDomain: String?
    public let topLevelDomain: String?
    public let secondLevelDomain: String?
    public let subDomain: String?
}
