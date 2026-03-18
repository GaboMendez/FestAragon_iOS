//
//  View+Extensions.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
// MARK: - Array Extension
extension Array where Element: Hashable {
    /// Retorna un array sin elementos duplicados, manteniendo el orden original
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        var result: [Element] = []
        for element in self {
            if !seen.contains(element) {
                seen.insert(element)
                result.append(element)
            }
        }
        return result
    }
}