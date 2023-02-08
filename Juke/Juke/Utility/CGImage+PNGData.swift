//
//  CGImage+PNGData.swift
//  Juke
//
//  Created by devin chalmers on 2/7/23.
//

import CoreGraphics
import Foundation
import ImageIO

extension CGImage {
    var pngData: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
    static func fromPNGData(_ data: Data?) -> CGImage? {
        guard let data = data, let dataProvider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}
