//
//  CGImage+NSImage.swift
//  Juke
//
//  Created by devin chalmers on 2/7/23.
//

import AppKit
import CoreGraphics
import Foundation

extension CGImage {
    var nsImage: NSImage {
        NSImage(cgImage: self, size: NSSize(width: self.width, height: self.height))
    }
}
