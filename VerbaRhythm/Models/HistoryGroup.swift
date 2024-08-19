//
//  HistoryGroup.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import Foundation

enum HistoryGroup: String, CaseIterable {
    case today = "Today"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case earlier = "Earlier"
}
