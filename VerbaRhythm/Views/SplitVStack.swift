//
//  SplitVStack.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 9/6/24.
//

import SwiftUI

struct SplitVStack<Content: View>: View {
    @State private var dragOffset: CGFloat = 0
    let content: Content
    let minHeight: CGFloat = 100 // Minimum height for the views

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                content
                    .frame(height: geometry.size.height / 2 + dragOffset)

                Divider()
                    .frame(height: 1)
                    .background(Color.gray)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newOffset = value.translation.height
                                let newHeight = geometry.size.height / 2 + dragOffset + newOffset

                                if newHeight > minHeight && newHeight < geometry.size.height - minHeight {
                                    dragOffset = newOffset
                                }
                            }
                    )

                content
                    .frame(height: geometry.size.height / 2 - dragOffset)
            }
        }
    }
}

#Preview {
    SplitVStack {
        Text("Split 1")
        Text("Split 2")
    }
}
