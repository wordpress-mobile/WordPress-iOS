package org.wordpress.emailchecker;

public class EmailChecker {
    static {
        System.loadLibrary("gnustl_shared");
        System.loadLibrary("emailchecker");
    }

    public native String suggestDomainCorrection(String email);
}
