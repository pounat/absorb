#if !__has_feature(objc_arc)
#error This file must be compiled with automatic reference counting enabled (-fobjc-arc)
#endif

#import "whisper-encoder.h"
#import "whisper-encoder-impl.h"

#import <CoreML/CoreML.h>

#include <stdlib.h>

#if __cplusplus
extern "C" {
#endif

struct whisper_coreml_context {
    const void * data;
};

struct whisper_coreml_context * whisper_coreml_init(const char * path_model) {
    NSString * path_model_str = [[NSString alloc] initWithUTF8String:path_model];
    NSURL * url_model = [NSURL fileURLWithPath: path_model_str];
    
    NSLog(@"[CoreML Debug] whisper_coreml_init called");
    NSLog(@"[CoreML Debug] Attempting to load from: %@", url_model.path);
    
    // Check file existence first
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:url_model.path isDirectory:&isDirectory];
    NSLog(@"[CoreML Debug] File exists: %d, Is directory: %d", fileExists, isDirectory);
    
    if (!fileExists) {
        NSLog(@"[CoreML Error] Model file/directory does not exist at path: %@", url_model.path);
        
        // List parent directory contents to help debug
        NSString *parentDir = [url_model.path stringByDeletingLastPathComponent];
        NSError *listError = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:parentDir error:&listError];
        if (contents) {
            NSLog(@"[CoreML Debug] Parent directory (%@) contains:", parentDir);
            for (NSString *item in contents) {
                NSLog(@"[CoreML Debug]   - %@", item);
            }
        } else {
            NSLog(@"[CoreML Debug] Failed to list parent directory: %@", listError.localizedDescription);
        }
        
        return NULL;
    }
    
    if (!isDirectory) {
        NSLog(@"[CoreML Error] Path exists but is not a directory (CoreML models must be .mlmodelc directories)");
        return NULL;
    }

    // select which device to run the Core ML model on
    MLModelConfiguration *config = [[MLModelConfiguration alloc] init];
    config.computeUnits = MLComputeUnitsAll;
    
    NSLog(@"[CoreML Debug] Starting MLModel initialization...");
    NSError *error = nil;
    const void * data = CFBridgingRetain([[whisper_encoder_impl alloc] initWithContentsOfURL:url_model configuration:config error:&error]);

    if (data == NULL) {
        NSLog(@"[CoreML Error] Failed to load CoreML model");
        if (error != nil) {
            NSLog(@"[CoreML Error] Error message: %@", error.localizedDescription);
            NSLog(@"[CoreML Error] Error domain: %@, Code: %ld", error.domain, (long)error.code);
            NSLog(@"[CoreML Error] Full error: %@", error);
        } else {
            NSLog(@"[CoreML Error] No NSError provided (initialization returned nil without error)");
        }
        return NULL;
    }
    
    NSLog(@"[CoreML Debug] CoreML model loaded successfully!");

    whisper_coreml_context * ctx = new whisper_coreml_context;

    ctx->data = data;

    return ctx;
}

void whisper_coreml_free(struct whisper_coreml_context * ctx) {
    CFRelease(ctx->data);
    delete ctx;
}

void whisper_coreml_encode(
        const whisper_coreml_context * ctx,
                             int64_t   n_ctx,
                             int64_t   n_mel,
                               float * mel,
                               float * out) {
    MLMultiArray * inMultiArray = [
        [MLMultiArray alloc] initWithDataPointer: mel
                                           shape: @[@1, @(n_mel), @(n_ctx)]
                                        dataType: MLMultiArrayDataTypeFloat32
                                         strides: @[@(n_ctx*n_mel), @(n_ctx), @1]
                                     deallocator: nil
                                           error: nil
    ];

    @autoreleasepool {
        whisper_encoder_implOutput * outCoreML = [(__bridge id) ctx->data predictionFromLogmel_data:inMultiArray error:nil];

        memcpy(out, outCoreML.output.dataPointer, outCoreML.output.count * sizeof(float));
    }
}

#if __cplusplus
}
#endif
