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

import XCTest
import Foundation
import UniformTypeIdentifiers
@testable import Magic

final class AlphabetTests: XCTestCase {
    func testUTType() throws {
        let type = UTType(data: "{}".data(using: .utf8)!)
        
        XCTAssertNotEqual(type, nil)
        XCTAssertEqual(type?.identifier, "public.json")
        XCTAssertEqual(type?.preferredMIMEType, "application/json")
    }
    
    func testMainType() throws {
        let types: [MediaType.MainType] = [
            .application, .audio, .example, .font, .haptics, .image, .message,
            .model, .multipart, .text, .video
        ]
        
        XCTAssertEqual(MediaType.MainType.standardTypes, Set(types))
        XCTAssertEqual(MediaType.MainType.application, "application")
        XCTAssertEqual(MediaType.MainType.audio, "audio")
        XCTAssertEqual(MediaType.MainType.example, "example")
        XCTAssertEqual(MediaType.MainType.font, "font")
        XCTAssertEqual(MediaType.MainType.haptics, "haptics")
        XCTAssertEqual(MediaType.MainType.image, "image")
        XCTAssertEqual(MediaType.MainType.message, "message")
        XCTAssertEqual(MediaType.MainType.model, "model")
        XCTAssertEqual(MediaType.MainType.multipart, "multipart")
        XCTAssertEqual(MediaType.MainType.text, "text")
        XCTAssertEqual(MediaType.MainType.video, "video")
        XCTAssertEqual(MediaType.MainType.ietf("app"), "app")
        XCTAssertEqual(MediaType.MainType.extension("x-app"), "x-app")
        for i in 0..<types.count {
            for j in 0..<types.count {
                XCTAssertEqual(i == j, types[i] == types[j])
                XCTAssertEqual(i < j, types[i] < types[j])
            }
        }
        XCTAssertNotEqual(MediaType.MainType.ietf("app"), .extension("app"))
        XCTAssertLessThan(MediaType.MainType.video, .ietf("app"))
        XCTAssertLessThan(MediaType.MainType.ietf("app"), .ietf("nil"))
        XCTAssertNotEqual(MediaType.MainType.extension("x-app"), .ietf("x-app"))
        XCTAssertLessThan(MediaType.MainType.ietf("app"), .extension("x-app"))
    }
    
    func testMimeType() throws {
        var type = MediaType("application/json; charset=utf-8")
        
        XCTAssertNotNil(type)
        XCTAssertEqual(type?.type, "application")
        XCTAssertEqual(type?.subtype, "json")
        XCTAssertEqual(type?.parameterValue(for: "CHARSET"), "utf-8")
        XCTAssertEqual(type?.description, "application/json; charset=utf-8")
        
        type = MediaType("text/vnd.json+yaml; charset=\"iso-8859-1\"; text=\"\\\"quoted\\\"\"")
        XCTAssertNotNil(type)
        XCTAssertEqual(type?.type, "text")
        XCTAssertEqual(type?.subtype, "vnd.json+yaml")
        XCTAssertEqual(type?.parameterValue(for: "Charset"), "iso-8859-1")
        XCTAssertEqual(type?.charset, .isoLatin1)
        XCTAssertEqual(type?.parameterValue(for: "Text"), "\"quoted\"")
        XCTAssertEqual(type?.description, "text/vnd.json+yaml; charset=\"iso-8859-1\"; text=\"\\\"quoted\\\"\"")
        
        type = MediaType("type/subtype; email=\"test\\x40example.com\"")
        XCTAssertNotNil(type)
        XCTAssertEqual(type?.type, "type")
        XCTAssertEqual(type?.subtype, "subtype")
        XCTAssertEqual(type?.parameterValue(for: "email"), "test@example.com")
        XCTAssertEqual(type?.description, "type/subtype; email=\"test\\x40example.com\"")
    }
    
    func testCreateMimeTypeString() throws {
        let jsonType = MediaType(type: .application, subtype: "json", parameters: .charset(.utf8))
        let soapType = MediaType(
            type: .application, subtype: "soap+xml",
            parameters: .charset(.utf8), .init(name: "action", value: "urn:CreateCredential")
        )
        var dynamicType = MediaType(type: .application, subtype: "soap+xml")
        
        dynamicType.setParameter(value: "utf-16", for: "charset")
        dynamicType.setParameter(value: "urn:CreateCredential", for: "action")
        XCTAssertEqual(jsonType.description, "application/json; charset=utf-8")
        XCTAssertEqual(jsonType.basicType, "application/json")
        XCTAssertEqual(soapType.description, "application/soap+xml; charset=utf-8; action=\"urn:CreateCredential\"")
        XCTAssertEqual(soapType.basicType, "application/soap+xml")
        XCTAssertEqual(dynamicType.description, "application/soap+xml; charset=utf-16; action=\"urn:CreateCredential\"")
        XCTAssertEqual(dynamicType.basicType, "application/soap+xml")
        dynamicType.setParameter(value: "urn:DeleteCredential", for: "action")
        XCTAssertEqual(dynamicType.description, "application/soap+xml; charset=utf-16; action=\"urn:DeleteCredential\"")
        dynamicType.removeParameter(for: "action")
        XCTAssertEqual(dynamicType.description, "application/soap+xml; charset=utf-16")
    }
    
    func testIanaCharsetName() throws {
        XCTAssertEqual(String.Encoding.ascii.ianaCharsetName, "us-ascii")
        XCTAssertEqual(String.Encoding.macOSRoman.ianaCharsetName, "macintosh")
        XCTAssertEqual(String.Encoding.nextstep.ianaCharsetName, "x-nextstep")
        XCTAssertEqual(String.Encoding.japaneseEUC.ianaCharsetName, "euc-jp")
        XCTAssertEqual(String.Encoding.shiftJIS.ianaCharsetName, "cp932")
        XCTAssertEqual(String.Encoding.utf8.ianaCharsetName, "utf-8")
        XCTAssertEqual(String.Encoding.utf16.ianaCharsetName, "utf-16")
        XCTAssertEqual(String.Encoding.utf16LittleEndian.ianaCharsetName, "utf-16le")
        XCTAssertEqual(String.Encoding.utf16BigEndian.ianaCharsetName, "utf-16be")
    }
    
    func testStringEncoding() throws {
        XCTAssertEqual(String.Encoding(ianaCharsetName: "ascii"), .ascii)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "ASCII"), .ascii)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "macintosh"), .macOSRoman)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "macroman"), .macOSRoman)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "x-nextstep"), .nextstep)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "euc-jp"), .japaneseEUC)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "shiftJIS"), .shiftJIS)
        
        XCTAssertEqual(String.Encoding(ianaCharsetName: "Latin1"), .isoLatin1)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "iso-8859-1"), .isoLatin1)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "Latin2"), .isoLatin2)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "iso-8859-2"), .isoLatin2)
        
        XCTAssertEqual(String.Encoding(ianaCharsetName: "CP1250"), .windowsCP1250)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "CP-1250"), .windowsCP1250)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "cp1250"), .windowsCP1250)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "cp-1250"), .windowsCP1250)
        
        XCTAssertEqual(String.Encoding(ianaCharsetName: "utf-8"), .utf8)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "UTF-8"), .utf8)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "utf8"), .utf8)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "UTF8"), .utf8)
        
        XCTAssertEqual(String.Encoding(ianaCharsetName: "utf-16"), .utf16)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "UTF-16"), .utf16)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "utf16"), .utf16)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "UTF16"), .utf16)
        
        XCTAssertEqual(String.Encoding(ianaCharsetName: "UTF-16LE"), .utf16LittleEndian)
        XCTAssertEqual(String.Encoding(ianaCharsetName: "UTF-16BE"), .utf16BigEndian)
        
        XCTAssertEqual(String.Encoding(ianaCharsetName: "abcdefgh"), nil)
    }
}
