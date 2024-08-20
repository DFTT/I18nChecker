//
//  LSFileScanner.swift
//  LocalStringFileCteater
//
//  Created by dadadongl on 2024/8/7.
//

import Foundation

class LSFileScanner {
    static func scan(from dirURL: URL) -> [LSFile] {
        let enumrator = FileManager.default.enumerator(at: dirURL,
                                                       includingPropertiesForKeys: [.isDirectoryKey],
                                                       options: [.skipsHiddenFiles,
                                                                 .skipsPackageDescendants])
        guard let enumrator = enumrator else {
            return []
        }

        var res = [LSFile]()

        for subURL in enumrator where subURL is URL {
            let subURL = subURL as! URL

            let isdic = try? subURL.resourceValues(forKeys: [.isDirectoryKey])
            if isdic?.isDirectory == true {
                // 过滤
                let directoryName = subURL.lastPathComponent

                let filters = [".framework", ".xcframework", ".bundle", ".xcassets"]
                let hit1 = filters.firstIndex { directoryName.range(of: $0) != nil }
                if hit1 != nil {
                    // 跳过该目录
                    enumrator.skipDescendants()
                    continue
                }

                let hit = ctx.excludeDirectoryNames.firstIndex { $0 == directoryName }
                if hit != nil {
                    // 跳过该目录
                    enumrator.skipDescendants()
                    continue
                }

                continue
            }

            //
            guard let type = TargetFileType(subURL.pathExtension) else {
                continue
            }
            let file = LSFile(url: subURL, type: type)
            // 扫描指定字符串
            if _scanTargetString(with: file) {
                res.append(file)
            }
        }

        return res
    }

    private static func _scanTargetString(with file: LSFile) -> Bool {
        guard let content = try? String(contentsOf: file.url, encoding: .utf8) else {
            return false
        }
        let matchedArr: [String] = Regix.matchStrings(from: content, with: file.type.regixParten)
        if matchedArr.isEmpty {
            return false
        }

        file.saveMatchedStrings(matchedArr)
        return true
    }
}
