#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <string>

static bool g_metal_usable = false;
static std::string g_metal_reason;

// Whisper's GPU startup and first run leave a marker that only a clean finish
// removes. One still there means the app died on the GPU, and the CPU takes
// over for the rest of this app version; the next update tries the GPU again.
static NSString * absorb_library_file(NSString * name) {
    NSString * dir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return dir == nil ? nil : [dir stringByAppendingPathComponent:name];
}

static NSString * absorb_build() {
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    return build ?: @"";
}

extern "C" void absorb_gpu_watch_begin() {
    @autoreleasepool {
        NSString * running = absorb_library_file(@"absorb_whisper_gpu_running");
        if (running != nil) [@"1" writeToFile:running atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
}

extern "C" void absorb_gpu_watch_end() {
    @autoreleasepool {
        NSString * running = absorb_library_file(@"absorb_whisper_gpu_running");
        if (running != nil) [[NSFileManager defaultManager] removeItemAtPath:running error:nil];
    }
}

static bool absorb_gpu_crashed_before() {
    NSString * running = absorb_library_file(@"absorb_whisper_gpu_running");
    NSString * failed = absorb_library_file(@"absorb_whisper_gpu_failed");
    if (running == nil || failed == nil) return false;
    NSFileManager * fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:running]) {
        [absorb_build() writeToFile:failed atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [fm removeItemAtPath:running error:nil];
    }
    NSString * failedBuild = [NSString stringWithContentsOfFile:failed encoding:NSUTF8StringEncoding error:nil];
    return failedBuild != nil && [failedBuild isEqualToString:absorb_build()];
}

static NSString * absorb_metallib_path() {
    Class cls = NSClassFromString(@"GGMLMetalClass");
    NSBundle * bundle = cls != nil ? [NSBundle bundleForClass:cls] : [NSBundle mainBundle];
    NSString * path = [bundle pathForResource:@"default" ofType:@"metallib"];
    if (path != nil) return path;
    NSString * resources = [bundle pathForResource:@"whisper_ggml_plus" ofType:@"bundle"];
    if (resources == nil) return nil;
    return [[NSBundle bundleWithPath:resources] pathForResource:@"default" ofType:@"metallib"];
}

// Whisper only runs on the GPU when its prebuilt kernels really work here.
// Below Apple7 (A14, iPhone 12) a kernel can fail to build and whisper runs it
// anyway, which took an iPhone 8 down. A default.metallib built for a newer
// iOS than the phone runs leaves whisper without a GPU backend while its
// weights already sit in GPU buffers, which aborted it on an iPhone 14 Pro on
// iOS 18. Either way the CPU takes over instead.
static void absorb_probe_metal() {
    @autoreleasepool {
        if (absorb_gpu_crashed_before()) {
            g_metal_reason = "whisper took the app down on the GPU last time on this app version";
            return;
        }
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (device == nil) {
            g_metal_reason = "no Metal device";
            return;
        }
        if (![device supportsFamily:MTLGPUFamilyApple7]) {
            g_metal_reason = "GPU is older than Apple7";
            [device release];
            return;
        }
        NSString * path = absorb_metallib_path();
        if (path == nil) {
            g_metal_reason = "default.metallib is missing";
            [device release];
            return;
        }
        NSError * error = nil;
        id<MTLLibrary> library = [device newLibraryWithURL:[NSURL fileURLWithPath:path] error:&error];
        if (library == nil) {
            g_metal_reason = std::string("default.metallib does not load: ") +
                (error != nil ? [[error localizedDescription] UTF8String] : "no reason given");
            [device release];
            return;
        }
        // The first kernel whisper runs, so a library this OS can't build
        // kernels from shows up here and not mid-transcription.
        id<MTLFunction> function = [library newFunctionWithName:@"kernel_im2col_f16"];
        if (function == nil) {
            g_metal_reason = "default.metallib has no usable kernel_im2col_f16";
            [library release];
            [device release];
            return;
        }
        id<MTLComputePipelineState> pipeline = [device newComputePipelineStateWithFunction:function error:&error];
        if (pipeline == nil) {
            g_metal_reason = std::string("Metal kernel does not build: ") +
                (error != nil ? [[error localizedDescription] UTF8String] : "no reason given");
        } else {
            g_metal_usable = true;
            [pipeline release];
        }
        [function release];
        [library release];
        [device release];
    }
}

static void absorb_probe_metal_once() {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ absorb_probe_metal(); });
}

extern "C" bool absorb_metal_usable() {
    absorb_probe_metal_once();
    return g_metal_usable;
}

/// Why whisper runs on the CPU, or an empty string when the GPU is fine.
extern "C" const char * absorb_metal_reason() {
    absorb_probe_metal_once();
    return g_metal_reason.c_str();
}
