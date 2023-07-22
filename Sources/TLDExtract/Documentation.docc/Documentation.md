# ``TLDExtract``

Swift package to extract top level domain (TLD), second level domain, subdomain and root domain

## Overview

```swift
import TLDExtract

let extractor = TLDExtract()

let urlString: String = "http://super.duper.domain.co.uk"
guard let result: TLDResult = extractor.parse(urlString) else { return }

print(result.rootDomain)        // Optional("domain.co.uk")
print(result.topLevelDomain)    // Optional("co.uk")
print(result.secondLevelDomain) // Optional("domain")
print(result.subDomain)         // Optional("super.duper")
```

## Topics

### Extracting

- ``TLDExtract/TLDExtract``
- ``TLDExtractable``
- ``TLDResult``
