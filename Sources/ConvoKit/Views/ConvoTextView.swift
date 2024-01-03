//
//  ConvoTextView.swift
//
//  Created by Andreas Ink on 12/23/23.
//

import SwiftUI

@available(iOS 17, *)
struct ConvoTextView: View {
    @State var magicText = [MagicText]()
    var body: some View {
        ScrollView {
            ForEach(magicText) { text in
                Text(text.text)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: text.text)
                    .scrollTransition(transition: { view, phase in
                        view
                            .blur(radius: phase.isIdentity ? 0 : 2)
                            .opacity(phase.isIdentity ? 1 : 0)
                    })
            }
//                .task {
//                    let text = """
//  My apologies for the confusion. In the context of a static property or method, you wouldn't have access to instance properties like frame. To resolve this, you'll need to set up your nodes at a time when you have the context of the scene's size, such as when you are initializing your scene or within the didMove(to:) method.
//
//Here's how you could adjust your code to create a left wall with the correct dimensions and position dynamically based on the scene's frame:
//"""
//                    var index = 0
//                    for sentence in text.split(separator: ". ") {
//                        self.magicText.append(MagicText(text: ""))
//
//                        for char in sentence {
//                            try? await Task.sleep(for: .seconds(0.05))
//                            self.magicText[index].text += String(char)
//                        }
//                        index += 1
//                    }
//                }
        }
        .padding()
        .padding(.top)
        .scrollClipDisabled()
        .background {
            if magicText.isEmpty == false {
                RoundedRectangle.bezelRectangle
                    .foregroundStyle(.ultraThinMaterial)
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    ConvoTextView()
}

struct MagicText: Identifiable {
    let id = UUID().uuidString
    var text: String
}
