#ifndef _Included_org_wordpress_emailchecker_EmailChecker
#define _Included_org_wordpress_emailchecker_EmailChecker

#include <string>
#include <jni.h>
#include "EmailDomainSpellChecker.h"

extern "C" {

JNIEXPORT jstring JNICALL Java_org_wordpress_emailchecker_EmailChecker_suggestDomainCorrection
  (JNIEnv *, jobject, jstring);

}
#endif
