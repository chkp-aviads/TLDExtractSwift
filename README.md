[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMarcoEidinger%2FTLDExtractSwift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/MarcoEidinger/TLDExtractSwift) [![Swit Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMarcoEidinger%2FTLDExtractSwift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/MarcoEidinger/TLDExtractSwift)

# TLDExtract

<img src="Metadata/domain-diagram.svg" alt="drawing" width="480" style="width:100%; max-width: 480px;"/>

<code>TLDExtract</code> is a Swift package to allows you extract
- root domain
- top level domain (TLD)
- second level domain
- subdomain

from a `URL` or a hostname `String`.

This is a fork to Kojiro Futamura's fantastic work on [gumob/TLDExtractSwift](https://github.com/gumob/TLDExtractSwift).

## Main differences to the original repo
- **Always up-to-date**
  - leveraging GitHub actions to regularly create new package versions bundling the latest [Public Suffix List](http://www.publicsuffix.org) (PSL) - perfect for offline use
  - modern `async` function to invoke a network request fetching the latest PSL from the remote server ad-hoc.
- **Swift Package Manager** (SPM) as the **exclusive distribution channel**
- No package dependencies

If you want to consume the library through CocoaPods or Carthage then please go ahead and use the [original repository](https://github.com/gumob/TLDExtractSwift).

## Usage

### Initialization

```swift
import TLDExtract

let extractor = TLDExtract()
```
### Extraction

#### Passing argument as String

Extract an url:

```swift
let urlString: String = "https://www.github.com/gumob/TLDExtract"
guard let result: TLDResult = extractor.parse(urlString) else { return }

print(result.rootDomain)        // Optional("github.com")
print(result.topLevelDomain)    // Optional("com")
print(result.secondLevelDomain) // Optional("github")
print(result.subDomain)         // Optional("www")
```

Extract a hostname:

```swift
let hostname: String = "gumob.com"
guard let result: TLDResult = extractor.parse(hostname) else { return }

print(result.rootDomain)        // Optional("gumob.com")
print(result.topLevelDomain)    // Optional("com")
print(result.secondLevelDomain) // Optional("gumob")
print(result.subDomain)         // nil
```

Extract an unicode hostname:

```swift
let hostname: String = "www.ラーメン.寿司.co.jp"
guard let result: TLDResult = extractor.parse(hostname) else { return }

print(result.rootDomain)        // Optional("寿司.co.jp")
print(result.topLevelDomain)    // Optional("co.jp")
print(result.secondLevelDomain) // Optional("寿司")
print(result.subDomain)         // Optional("www.ラーメン")
```

Extract a punycoded hostname (Same as above):

```swift
let hostname: String = "www.xn--4dkp5a8a.xn--sprr0q.co.jp")"
guard let result: TLDResult = extractor.parse(hostname) else { return }

print(result.rootDomain)        // Optional("xn--sprr0q.co.jp")
print(result.topLevelDomain)    // Optional("co.jp")
print(result.secondLevelDomain) // Optional("xn--sprr0q")
print(result.subDomain)         // Optional("www.xn--4dkp5a8a")
```

#### Passing argument as Foundation URL

Extract an unicode url: <br/>
URL class in Foundation Framework does not support unicode URLs by default. You can use URL extension as a workaround
```swift
let urlString: String = "http://www.ラーメン.寿司.co.jp"
let url: URL = URL(unicodeString: urlString)
guard let result: TLDResult = extractor.parse(url) else { return }

print(result.rootDomain)        // Optional("www.ラーメン.寿司.co.jp")
print(result.topLevelDomain)    // Optional("co.jp")
print(result.secondLevelDomain) // Optional("寿司")
print(result.subDomain)         // Optional("www.ラーメン")
```

Encode an url by passing argument as percent encoded string (Same as above):
```swift
let urlString: String = "http://www.ラーメン.寿司.co.jp".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
let url: URL = URL(string: urlString)
print(urlString)                // http://www.%E3%83%A9%E3%83%BC%E3%83%A1%E3%83%B3.%E5%AF%BF%E5%8F%B8.co.jp

guard let result: TLDResult = extractor.parse(url) else { return }

print(result.rootDomain)        // Optional("www.ラーメン.寿司.co.jp")
print(result.topLevelDomain)    // Optional("co.jp")
print(result.secondLevelDomain) // Optional("寿司")
print(result.subDomain)         // Optional("www.ラーメン")
```

### Ad-hoc fetching of PSL

This repository publishes new versions with the latest PSL regularly. This should be sufficient for most app developers assuming you are [updating to the latest version]( https://blog.eidinger.info/how-to-catch-up-with-outdated-dependencies-in-your-swift-package-with-github-actions-141d3d06b1d0).

Nevertheless, an `async` function allows to invoke a network request fetching the latest PSL from the remote server ad-hoc. 

```swift
import TLDExtract

let extractor = TLDExtract()
try await extractor.fetchLatestPSL()
```

**Requires network connectivity!**