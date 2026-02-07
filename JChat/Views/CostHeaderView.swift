//
//  CostHeaderView.swift
//  JChat
//

import SwiftUI

struct CostHeaderView: View {
    let chat: Chat?
    
    var body: some View {
        HStack(spacing: 16) {
            if let chat = chat {
                Label("\(chat.totalTokens) tokens", systemImage: "number")
                    .font(.caption)
                
                Divider()
                
                Label("$\(chat.totalCost, format: .number.precision(.fractionLength(4)))", systemImage: "dollarsign.circle")
                    .font(.caption)
                
                Spacer()
            } else {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
