//
//  TLDExtract.swift
//  TLDExtract
//
//  Created by kojirof on 2018/11/16.
//  Copyright © 2018 Gumob. All rights reserved.
//

import Foundation

/// Class to extract root domain, top level domain (TLD), second level domain or subdomain from a `URL` or hostname `String`
///  This is possible thanks to a bundled version of the [Public Suffix List](https://publicsuffix.org/)
///  You can also fetch the most up-to-date PSL with async function ``fetchLatestPSL``
public class TLDExtract {

    private var tldParser: TLDParser

    public init() {
        let url = Bundle.module.url(forResource: "public_suffix_list", withExtension: "dat")!
        let data: Data = try! Data(contentsOf: url)
        let dataSet = try! PSLParser().parse(data: data)
        self.tldParser = TLDParser(dataSet: dataSet)
    }
    
    /// invoke network request to fetch latest Public Suffix List (PSL) from a remote server ensuring that extractor operates most accurate
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public func fetchLatestPSL() async throws {
        let url: URL = URL(string: "https://publicsuffix.org/list/public_suffix_list.dat")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let dataSet = try PSLParser().parse(data: data)
        self.tldParser = TLDParser(dataSet: dataSet)
    }

    /// Parameters:
    ///   - host: Hostname to be extracted
    ///   - quick: If true, parse only normal data excluding exceptions and wildcards
    public func parse<T: TLDExtractable>(_ input: T, quick: Bool = false) -> TLDResult? {
        guard let host: String = input.hostname else { return nil }
        if quick {
            return self.tldParser.parseNormals(host: host)
        } else {
            return self.tldParser.parseExceptionsAndWildcards(host: host) ??
                   self.tldParser.parseNormals(host: host)
        }
    }
}

/// Protocol
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
        let schemePattern: String = "^(\\p{L}+:)?//"
        let hostPattern: String = "([0-9\\p{L}][0-9\\p{L}-]{1,61}\\.?)?   ([\\p{L}-]*  [0-9\\p{L}]+)  (?!.*:$).*$".replace(" ", "")
        if self.matches(schemePattern) {
            let components: [String] = self.replace(schemePattern, "").components(separatedBy: "/")
            guard let component: String = components.first, !component.isEmpty else { return nil }
            return component
        } else if self.matches("^\(hostPattern)") {
            let components: [String] = self.replace(schemePattern, "").components(separatedBy: "/")
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
        return regex.matches(in: self, range: NSRange(location: 0, length: self.count)).count > 0
    }

    func replace(_ pattern: String, _ replacement: String) -> String {
        return self.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }
}

/**
 Result structure
 
 /// EXAMPLE:
 ```swift
 let urlString: String = "https://www.github.com/gumob/TLDExtract"
 guard let result: TLDResult = extractor.parse(urlString) else { return }

 print(result.rootDomain)        // Optional("github.com")
 print(result.topLevelDomain)    // Optional("com")
 print(result.secondLevelDomain) // Optional("github")
 print(result.subDomain)         // Optional("www")
 ```
**/
public struct TLDResult {
    public let rootDomain: String?
    public let topLevelDomain: String?
    public let secondLevelDomain: String?
    public let subDomain: String?
}
