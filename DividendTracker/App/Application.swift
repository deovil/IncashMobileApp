//
//  Application.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 21/01/26.
//

import UIKit

extension UIApplication {
    var rootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
