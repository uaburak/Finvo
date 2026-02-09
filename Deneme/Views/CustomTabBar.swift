//
//  CustomTabBar.swift
//  CustomGlassTabBar
//
//  Created by Balaji Venkatesh on 28/09/25.
//

import SwiftUI

struct CustomTabBar<TabItemView: View>: UIViewRepresentable {
    var size: CGSize
    var activeTint: Color = .primary
    var inActiveTint: Color = .primary.opacity(0.45)
    var barTint: Color = .gray.opacity(0.2)
    @Binding var activeTab: CustomTab
    @ViewBuilder var tabItemView: (CustomTab) -> TabItemView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let items = CustomTab.allCases.map(\.rawValue)
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = activeTab.index
        
        /// Converting Tab Item View into an image!
        for (index, tab) in CustomTab.allCases.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab))
            renderer.scale = 2
            let image = renderer.uiImage
            control.setImage(image, forSegmentAt: index)
        }
        
        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }
        
        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([.foregroundColor: UIColor(activeTint)], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor(inActiveTint)], for: .normal)
        
        control.addTarget(context.coordinator, action: #selector(context.coordinator.tabSelected(_:)), for: .valueChanged)
        
        // Container View for Custom Padding (2px)
        let container = UIView()
        container.addSubview(control)
        control.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            control.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            control.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -3),
            control.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 2),
            control.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -2)
        ])
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No heavy updates needed for now, handled by state binding via Coordinator
        if let control = uiView.subviews.first as? UISegmentedControl {
            control.selectedSegmentIndex = activeTab.index
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        return size
    }
    
    class Coordinator: NSObject {
        var parent: CustomTabBar
        init(parent: CustomTabBar) {
            self.parent = parent
        }
        
        @objc func tabSelected(_ control: UISegmentedControl) {
            parent.activeTab = CustomTab.allCases[control.selectedSegmentIndex]
        }
    }
}

#Preview {
    ContentView()
}
