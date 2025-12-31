#include <jni.h>
#include "tejaslistOnLoad.hpp"

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  return margelo::nitro::tejaslist::initialize(vm);
}
