/*
 Copyright 2025 macoonshine
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UniformTypeIdentifiers

public extension UTType {
    private static var magic: Magic {
        return .init(definitions: .default, .system, .builtin)!
    }

    /// create a type given a file path, by determining the MIME type of the file.
    /// - Parameter data: a data object
    /// - Returns a type  or nil if no suitable type could be determined.
    init?(path: String) {
        if let mimeType = Self.magic.file(path: path) {
            self.init(mimeType: mimeType)
        }
        else {
            return nil
        }
    }
    
    /// create a type given a data object, by determining the MIME type of the data.
    /// - Parameter data: a data object
    /// - Returns a type  or nil if no suitable type could be determined.
    init?(data: Data) {
        if let mimeType = Self.magic.file(data: data) {
            self.init(mimeType: mimeType)
        }
        else {
            return nil
        }
    }
}
