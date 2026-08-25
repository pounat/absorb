#ifndef WHISPER_GGML_PLUS_WINDOWS_H_
#define WHISPER_GGML_PLUS_WINDOWS_H_

#if defined(_MSC_VER)
#define FUNCTION_ATTRIBUTE __declspec(dllexport)
#elif defined(__GNUC__)
#define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#else
#define FUNCTION_ATTRIBUTE
#endif

#ifdef __cplusplus
extern "C" {
#endif

FUNCTION_ATTRIBUTE char *request(char *body);
FUNCTION_ATTRIBUTE void free_string(char *ptr);

#ifdef __cplusplus
}
#endif

#endif
