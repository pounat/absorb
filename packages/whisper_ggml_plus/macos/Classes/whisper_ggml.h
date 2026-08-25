#if defined(__GNUC__)
// Attributes to prevent 'unused' function from being removed and to make it visible
#define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
// Marking a function for export
#define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif

#ifdef __cplusplus
extern "C"
{
#endif

FUNCTION_ATTRIBUTE char *request(char *body);
FUNCTION_ATTRIBUTE void free_string(char *ptr);

#ifdef __cplusplus
}
#endif
