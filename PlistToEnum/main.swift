//
//  main.swift
//  PlistToEnum
//
//  Created by Suraj Pathak on 20/11/16.
//  Copyright © 2016 Suraj Pathak. All rights reserved.
//

import Foundation

let template: String = "\n" +
    "import Foundation\n" +
    "\n" +
    "protocol PathType {}\n" +
    "extension Int: PathType {}\n" +
    "extension String: PathType {}\n" +
    "\n" +
    "\n" +
    "public enum PKeys {\n" +
        "{CASES}\n" +
    "\n" +
        "\tvar keys: [PathType] {\n" +
            "\t switch self {\n" +
            "{CASESRESULTS}\n" +
            "\t\t }\n" +
        "\t }\n" +
    "\n" +
    "}\n" +
    "\n" +
    "\n" +
    "class PlistConfig {\n" +
    "\n" +
    "\t let plistOutput: Any\n" +
    "\n" +
    "\t private init() {\n" +
            "\t\t if let url = Bundle.main.url(forResource: \"{FILENAME}\", withExtension: \"plist\") {\n" +
                "\t\t\t if let dict = NSDictionary(contentsOf: url) as? [String: Any] {\n" +
                    "\t\t\t\t plistOutput = dict\n" +
                "\t\t\t } else if let array = NSArray(contentsOf: url) as? [Any] {\n" +
                    "\t\t\t\t plistOutput = array\n" +
                "\t\t\t } else {\n" +
                    "\t\t\t\t plistOutput = []\n" +
                "\t\t\t }\n" +
            "\t\t } else {\n" +
                "\t\t\t plistOutput = []\n" +
            "\t\t }\n" +
        "\t }\n" +
    "\n" +
    "\n" +
        "\t func valueFor(_ keyPath: [PathType]) -> Any? {\n" +
            "\t\t let count = keyPath.count\n" +
            "\t\t var finalValue: Any? = plistOutput\n" +
            "\t\t for i in 0..<count {\n" +
            "\t\t\t let path = keyPath[i]\n" +
            "\t\t\t if let dictPath = path as? String {\n" +
                "\t\t\t\t if let newValue = finalValue as? [String: Any] {\n" +
                    "\t\t\t\t\t finalValue = newValue[dictPath]\n" +
                "\t\t\t\t } else {\n" +
                    "\t\t\t\t\t return nil\n" +
                "\t\t\t\t }\n" +
            "\t\t\t } else if let arrayPath = path as? Int {\n" +
                "\t\t\t\t if let newValue = finalValue as? [Any], arrayPath < newValue.count {\n" +
                    "\t\t\t\t\t finalValue = newValue[arrayPath]\n" +
                "\t\t\t\t } else {\n" +
                    "\t\t\t\t\t return nil\n" +
                "\t\t\t\t }\n" +
            "\t\t\t }\n" +
        "\t\t }\n" +
            "\t\t return finalValue\n" +
        "\t\t }\n" +
        "\n" +
"}\n" +
"\n"


class File {
    class func exists(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    class func readPlist(url: URL) -> Any {
        if let dict = NSDictionary(contentsOf: url) as? [String: Any] {
            return dict
        } else if let array = NSArray(contentsOf: url) as? [Any] {
            return array
        } else {
            return []
        }
    }
    
    class func write (path: String, content: String, encoding: String.Encoding = String.Encoding.utf8) -> Bool {
        return ((try? content.write(toFile: path, atomically: true, encoding: encoding)) != nil) ?true :false
    }
    
    class func write(url: URL, content: String, encoding: String.Encoding = String.Encoding.utf8) -> Bool {
        return ((try? content.write(to: url, atomically: true, encoding: encoding)) != nil) ?true :false
    }
    
}

protocol Keypathable {}
extension Int: Keypathable {}
extension String: Keypathable {}

class PlistEnum {
    
    struct PlistKey: CustomStringConvertible {
        let keys: [Keypathable]
        
        func keyByAppending(_ key: Keypathable) -> PlistKey {
            var myKeys = keys
            myKeys.append(key)
            return PlistKey(keys: myKeys)
        }
        
        var keyCase: String {
            var keyArray: [String] = []
            for k in keys {
                keyArray.append("\(k)")
            }
            return keyArray.joined(separator: "_")
        }
        
        var description: String {
            return keys.description
        }
        
    }
    
    let file: String
    let plistOutput: Any
    
    required init(filename: String, url: URL) {
        file = filename
        plistOutput = File.readPlist(url: url)
    }
    
    func run() {
        var keys: [PlistKey] = []
        
        // Reads a dictionary
        func checkDict(_ dictionary: [String: Any], plistKey: PlistKey) {
            for (key, value) in dictionary {
                if let array = value as? [Any] {
                    checkArray(array, plistKey: plistKey.keyByAppending(key))
                } else if let dict = value as? [String: Any] {
                    checkDict(dict, plistKey: plistKey.keyByAppending(key))
                } else {
                    keys.append(plistKey.keyByAppending(key))
                }
            }
        }
        
        // Reads an array
        func checkArray(_ array: [Any], plistKey: PlistKey) {
            for (index, value) in array.enumerated() {
                if let array = value as? [Any] {
                    checkArray(array, plistKey: plistKey.keyByAppending(index))
                } else if let dict = value as? [String: Any] {
                    checkDict(dict, plistKey: plistKey.keyByAppending(index))
                } else {
                    keys.append(plistKey.keyByAppending(index))
                }
            }
        }
        
        if let output = plistOutput as? [String: Any] {
            checkDict(output, plistKey: PlistKey(keys: []))
        } else if let output = plistOutput as? [Any] {
            checkArray(output, plistKey: PlistKey(keys: []))
        }
        
        // Step 3. Generate enum from the keys
        
        var cases: [String] = []
        var caseResult: [String] = []
        for plistKey in keys {
            cases.append("\t case \(plistKey.keyCase)")
            caseResult.append("\t\t case .\(plistKey.keyCase): return \(plistKey.keys)")
        }
        let content = template.replacingOccurrences(of: "{FILENAME}", with: file)
        let contentCases = content.replacingOccurrences(of: "{CASES}", with: cases.joined(separator: "\n"))
        let finalContent = contentCases.replacingOccurrences(of: "{CASESRESULTS}", with: caseResult.joined(separator: "\n"))
        let output = Bundle.main.bundlePath
        let _ = File.write(path: output + "/PListConfig.swift", content: finalContent )
    }
    
}

if let url = Bundle.main.url(forResource: "example", withExtension: "plist") {
    let enumGenerator = PlistEnum(filename: "example", url: url)
    enumGenerator.run()
}
