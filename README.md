# Magic

[![Magic tests](https://github.com/macmoonshine/magic/actions/workflows/swift.yml/badge.svg)](https://github.com/macmoonshine/magic/actions/workflows/swift.yml)
[![Swift](https://img.shields.io/badge/Swift-5.10%2B-orange?logo=swift)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2015%2B%20%7C%20macOS%2011%2B-blue?logo=apple)](https://github.com/macmoonshine/magic/blob/main/Package.swift)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](https://github.com/macmoonshine/magic/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/macmoonshine/magic)](https://github.com/macmoonshine/magic/issues)
[![GitHub stars](https://img.shields.io/github/stars/macmoonshine/magic)](https://github.com/macmoonshine/magic/stargazers)

This library allows you to determine the MIME type or UTType for any data  and is a Swift wrapper for [libmagic(3)](https://github.com/file/file) which is part of [file(1)](https://www.darwinsys.com/file/) command.

* Sources for libmagic: <https://github.com/apple-opensource/file>
* Home page for file: <https://www.darwinsys.com/file/>

## Building libmagic

The C sources of libmagic are not part of this repository. A
[`Makefile`](Makefile) downloads, compiles and bundles them into the
[`libmagic.xcframework`](Frameworks/libmagic.xcframework) and compiles the
`magic.mgc` definitions file into [`Sources/Magic/Resources`](Sources/Magic/Resources).

The `Makefile` should be executed only if you wish to use another version of
libmagic. To do so, update the version number in
[`libmagic.version`](libmagic.version) and run `make`:

```sh
make
```

Alternatively, you can also pass the version to `make` using the `VERSION` variable:

```sh
make VERSION=5.48
```

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

## Breaking Changes

### Version 1.1

`Magic.Definition.system` — the definition file of the system's `file` command
— was removed in version 1.1. Use `.builtin` instead, which uses the magic
definitions bundled with this package.

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

The bundled `libmagic` (`Frameworks/libmagic.xcframework` and
`Sources/Magic/Resources/magic.mgc`) is derived from `file(1)` and subject to
its own copyright and license:

Copyright (c) Ian F. Darwin 1986, 1987, 1989, 1990, 1991, 1992, 1994, 1995.
Software written by Ian F. Darwin and others;
maintained 1994- Christos Zoulas.

This software is not subject to any export provision of the United States
Department of Commerce, and may be exported to any country or planet.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright notice
   immediately at the beginning of the file, without modification, this
   list of conditions, and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
