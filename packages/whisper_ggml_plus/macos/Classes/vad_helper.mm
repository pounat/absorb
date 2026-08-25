#import <Foundation/Foundation.h>

extern "C" const char* get_vad_model_path() {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *vadPath = [mainBundle pathForResource:@"flutter_assets/assets/models/ggml-silero-v6.2.0" ofType:@"bin"];
    
    if (vadPath != nil) {
        return [vadPath UTF8String];
    }
    return nullptr;
}
