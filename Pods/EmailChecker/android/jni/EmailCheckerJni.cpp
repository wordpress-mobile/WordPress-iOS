#include "EmailCheckerJni.h"
#include "EmailDomainSpellChecker.h"

JNIEXPORT jstring JNICALL Java_org_wordpress_emailchecker_EmailChecker_suggestDomainCorrection
    (JNIEnv *env, jobject obj, jstring jStringEmail) {
    const char *nativeString = env->GetStringUTFChars(jStringEmail, 0);
    std::string email = std::string(nativeString);
    EmailDomainSpellChecker edsc;
    std::string resString = edsc.suggestDomainCorrection(email);
    env->ReleaseStringUTFChars(jStringEmail, nativeString);
    return env->NewStringUTF(resString.data());
}
