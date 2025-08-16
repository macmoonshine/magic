# Magic

This library allows you to determine the MIME type or UTType for any data  and is a Swift wrapper for [libmagic(3)](https://github.com/file/file) which is part of [file(1)](https://www.darwinsys.com/file/) command. This implementation is based on Apple's adaptation of libmagic for macOS.

* Sources for libmagic: <https://github.com/apple-opensource/file>
* Home page for file: <https://www.darwinsys.com/file/>

## Installation

### Xcode

you can include Magic in your Xcode project via 
_File_ | _Swift Packages_ | _Add Package Dependencies..._. In the first step 
of the wizard use the URL 
[https://github.com/macmoonshine/magic](https://github.com/macmoonshine/magic.git), 
press _Next_ and following the remaining steps of the wizard.

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/macmoonshine/magic.git"),
],
targets: [
    .target(
      name: "MyTarget",
      dependencies: [.product(name: "Magic", package: "Magic")]
    ),
]
```
 
## Examples

You can use the class `Magic` to determine the media type of files or data as a 
string.

```swift
import Magic

let magic = Magic(definition: .default)
let data: Data! = "{}".data(using: .utf8)
let path = "..."

print(magic.file(data: data))
print(magic.file(path: path))
```

The `definition: default` directive tells libmagic to use the default location 
for the `magic.mgc` file. But you can also use your own file via:

```swift
let magic = Magic(definition: .path("/.../magic.mgc"))
```

Further possibilities can be found in `Magic.Definition`. Without a definition, 
the initialisation of `Magic` will fail.

Magic also offers an extension for Apple's _Uniform Type Identifiers_:

```swift
import Magic
import UniformTypeIdentifiers

let data: Data! = "{}".data(using: .utf8)
let dataType = UTType(data: data)
let fileTye = UTType(path: "...")
```

Furthermore, Magic provides the struct `MediaType`, which was implemented on the
basis of [RFC 2045 Section 5.1](https://www.rfc-editor.org/rfc/rfc2045#section-5.1) 
and that allows easy access to the properties of media types. This allows, for 
example, a simple selection of views in SwiftUI depending on the data content.

```swift
import Magic
import SwiftUI

struct Preview: View {
    @State var data: Data
    
    var mediaType: MediaType? {
        return MediaType(data: data)
    }
    
    var body: some View {
        if let mediaType = mediaType {
            switch mediaType.mainType {
            case .audio:
                AudioPlayer(data: data)
            case .image:
                ImagePreview(data: data)
            case .text:
                TextPreview(data: data, encoding: mediaType.charset)
            default:
                Text("No preview available.")
            }
        }
        else {
            Text("Cannot determine media type.")        
        }
    }
}
```

The MediaType structure also makes it easy to create syntactically 
correct media type strings:

```swift
import Magic

let mediaType = MediaType(
    type: .application, subtype: "soap+xml", 
    parameters: .charset(.utf8), .init(name: "action", value: "urn:CreateCredential")
)
let headers = ["Content-Type": mediaType.description]
```

## License

Copyright 2025 macoonshine

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
