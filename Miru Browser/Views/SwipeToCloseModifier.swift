//
//  SwipeToCloseModifier.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/6/25.
//

import SwiftUI
import UIKit

// MARK: - Swipe to Close Container View

struct SwipeToCloseContainer<Content: View>: View {
  let content: Content
  let onClose: () -> Void
  
  @State private var dragOffset: CGFloat = 0
  @State private var isClosing: Bool = false
  @State private var hasReachedThreshold: Bool = false
  @State private var containerWidth: CGFloat = 0
  
  // Constants
  private var closeThreshold: CGFloat { max(containerWidth * 0.4, 1) }
  private let maxRotation: Double = -8
  
  // Computed properties
  private var progress: CGFloat {
    guard dragOffset < 0 else { return 0 }
    return min(abs(dragOffset) / closeThreshold, 1.0)
  }
  
  private var redBackgroundOpacity: Double {
    // Fade out during close animation
    if isClosing { return 0 }
    // Accelerate the red fade - starts subtle, ramps up quickly
    return Double(pow(progress, 0.7))
  }
  
  private var rotation: Double {
    maxRotation * Double(progress)
  }
  
  private var scale: CGFloat {
    isClosing ? 0.7 : 1.0 - (progress * 0.15)
  }
  
  private var contentOpacity: Double {
    isClosing ? 0 : 1.0
  }
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Red background that fades in and out
        Color.red
          .opacity(redBackgroundOpacity)
          .animation(.easeOut(duration: 0.25), value: isClosing)
          .ignoresSafeArea()
        
        // Close indicator icon - appears as you swipe
        if progress > 0.15 && !isClosing {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 56, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .scaleEffect(0.6 + (progress * 0.5))
            .opacity(Double(progress))
        }
        
        // Main content
        content
          .offset(x: isClosing ? -geometry.size.width : dragOffset)
          .rotationEffect(.degrees(rotation), anchor: .bottomTrailing)
          .scaleEffect(scale, anchor: .trailing)
          .opacity(contentOpacity)
      }
      .onAppear { containerWidth = geometry.size.width }
      .onChange(of: geometry.size.width) { _, newWidth in containerWidth = newWidth }
      .gesture(
        // Starts only from the right screen edge, so horizontal swipes on the
        // page itself (carousels, slideshows, maps) stay with the page.
        RightEdgeSwipeGesture(
          onChanged: { translation in
            guard !isClosing else { return }
            dragOffset = min(translation, 0) * 0.8

            // Haptic once when crossing the threshold
            if abs(dragOffset) >= closeThreshold && !hasReachedThreshold {
              hasReachedThreshold = true
              UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else if abs(dragOffset) < closeThreshold {
              hasReachedThreshold = false
            }
          },
          onEnded: { cancelled in
            guard !isClosing else { return }
            if hasReachedThreshold && !cancelled {
              triggerClose(screenWidth: geometry.size.width)
            } else {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                dragOffset = 0
              }
            }
            hasReachedThreshold = false
          }
        )
      )
    }
  }

  private func triggerClose(screenWidth: CGFloat) {
    isClosing = true
    
    // Animate off screen
    withAnimation(.easeOut(duration: 0.25)) {
      dragOffset = -screenWidth
    }
    
    // Call close after animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      onClose()
      
      // Reset state
      dragOffset = 0
      isClosing = false
    }
  }
}

// MARK: - Right Edge Swipe Gesture

/// A swipe that must begin at the right edge of the screen, reported as the
/// horizontal translation (negative when moving left).
private struct RightEdgeSwipeGesture: UIGestureRecognizerRepresentable {
  let onChanged: (CGFloat) -> Void
  let onEnded: (_ cancelled: Bool) -> Void

  func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
    Coordinator()
  }

  func makeUIGestureRecognizer(context: Context) -> UIScreenEdgePanGestureRecognizer {
    let recognizer = UIScreenEdgePanGestureRecognizer()
    recognizer.edges = .right
    recognizer.delegate = context.coordinator
    return recognizer
  }

  func handleUIGestureRecognizerAction(
    _ recognizer: UIScreenEdgePanGestureRecognizer, context: Context
  ) {
    switch recognizer.state {
    case .began, .changed:
      onChanged(recognizer.translation(in: recognizer.view).x)
    case .ended:
      onEnded(false)
    case .cancelled, .failed:
      onEnded(true)
    default:
      break
    }
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    // Win over WebKit's own edge swipe (forward navigation) from the same edge.
    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
  }
}

// MARK: - View Extension

extension View {
  func swipeToClose(onClose: @escaping () -> Void) -> some View {
    SwipeToCloseContainer(content: self, onClose: onClose)
  }
}

