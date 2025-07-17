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

import Foundation

extension Scanner {
    func lookahead(length: Int) -> String? {
        let startIndex = currentIndex
        let endIndex = string.index(startIndex, offsetBy: length)
        
        return endIndex > string.endIndex ? nil : String(string[startIndex..<endIndex])
    }
    
    func scanUInt64(length: Int, radix: Int) -> UInt64? {
        if let prefix = lookahead(length: length), let value = UInt64(prefix, radix: radix) {
            _ = scanString(prefix)
            return value
        }
        else {
            return nil
        }
    }
    
    func scanHexadecimalCharacter(length: Int) -> Character? {
        var value = ""
        
        for _ in 0..<length {
            if let digit = scanCharacter() {
                switch digit {
                case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                    "a", "b", "c", "d", "e", "f", "A", "B", "C", "D", "E", "F":
                    value += String(digit)
                default:
                    return nil
                }
            }
        }
        if let value = Int(value, radix: 16), let scalar = UnicodeScalar(value) {
            return Character(scalar)
        }
        else {
            return nil
        }
    }
}
