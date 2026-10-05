#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

// Whisper's Metal kernels target the Apple7 GPU family and up (A14, iPhone 12).
// Below that a kernel can fail to build and whisper runs it anyway, which took
// the app down on an iPhone 8. Those devices get the CPU instead.
extern "C" bool absorb_metal_usable() {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device == nil) return false;
    if (@available(iOS 13.0, *)) {
        return [device supportsFamily:MTLGPUFamilyApple7];
    }
    return false;
}
