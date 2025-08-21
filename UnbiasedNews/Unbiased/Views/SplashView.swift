import SwiftUI

struct SplashView: View {
    @State var isActive: Bool = true
    @State private var scale: CGFloat = 0.8
    @State private var rotationAngle: Double = 0.0
    @State private var unbiasedScale: CGFloat = 0.0
    @State private var unbiasedOpacity: Double = 0.0

    var body: some View {
        if !isActive {
            ContentView() //Navigates to contentview after animation
        } else {
            ZStack {
                Color.black.ignoresSafeArea()
                
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .scaleEffect(scale)
                    .rotationEffect(Angle.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(
                            Animation.easeInOut(duration: 3)
                                .repeatCount(1, autoreverses: true)
                        ) {
                            self.scale = 2.3 // Zoom in and out
                        }
                        withAnimation(
                            Animation.linear(duration: 3)
                        ) {
                            self.rotationAngle = 360 // Rotate 360 degrees
                        }
                    }
                
         
                Image("Unbiased")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .scaleEffect(unbiasedScale) // Scale animation
                    .opacity(unbiasedOpacity) // Fade-in animation
                    .onAppear {
                        withAnimation(
                            Animation.easeOut(duration: 1.5).delay(2)
                        ) {
                            self.unbiasedScale = 1.0 // Grow to full size
                            self.unbiasedOpacity = 1.0 // Fully visible
                        }
                    }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        self.isActive = false
                    }
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}


