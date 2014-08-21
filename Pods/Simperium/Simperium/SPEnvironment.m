//
//  SPEnvironment.m

#import "SPEnvironment.h"

// Production
NSString* const SPBaseURL                       = @"https://api.simperium.com/1/";
NSString* const SPAuthURL                       = @"https://auth.simperium.com/1/";
NSString* const SPWebsocketURL                  = @"wss://api.simperium.com/sock/1";

NSString* const SPAPIVersion                    = @"1.1";

#if TARGET_OS_IPHONE
NSString* const SPLibraryID                     = @"ios";
#else
NSString* const SPLibraryID                     = @"osx";
#endif

// TODO: Update this automatically via a script that looks at current git tag
NSString* const SPLibraryVersion                = @"0.6.6";

// SSL Certificate Expiration: '2016-09-07 02:36:04 +0000' expressed as seconds since 1970
NSTimeInterval const SPCertificateExpiration    = 1473215764;

// Note:
// The PEM certificate can be obtained by means of openssl cli:
//      > openssl s_client -showcerts -host api.simperium.com -port 443
//
NSString* const SPCertificatePayload            = @"MIIFKTCCBBGgAwIBAgIHJ/SM4X239zANBgkqhkiG9w0BAQsFADCBtDELMAkGA1UE"
                                                    @"BhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAY"
                                                    @"BgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQLEyRodHRwOi8vY2VydHMu"
                                                    @"Z29kYWRkeS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMTKkdvIERhZGR5IFNlY3Vy"
                                                    @"ZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjAeFw0xNDA0MTEwMjU1MDZaFw0x"
                                                    @"NjA5MDcwMjM2MDRaMD0xITAfBgNVBAsTGERvbWFpbiBDb250cm9sIFZhbGlkYXRl"
                                                    @"ZDEYMBYGA1UEAwwPKi5zaW1wZXJpdW0uY29tMIIBIjANBgkqhkiG9w0BAQEFAAOC"
                                                    @"AQ8AMIIBCgKCAQEAsoMehiDU1gW0gL8XvAm8+ojYXpOWOOi/Fc3bS2lFf6pVRMao"
                                                    @"W3CxmakK/GERwTsdB8AwRxp5GkeHXeIax54QzqtDVlFzTeWC3MKFenJoesSGy4aR"
                                                    @"7k+zm9h9sYrSPrvaBgAu+9PU+xVREDPKtVASfJWBik5vvot+oJAa7nFa/9qF4tJm"
                                                    @"ecvIc+39u8LaSGYY4Pct1o55wVbpNnGJWQofzbRuyCJQK+f1hy+N5DTo1Yk+pnNS"
                                                    @"eaGNxN8s8FsJQxV4lShxW+JQyLgqj+7OPPuYeBjeqXBXUkfjtdmz/yWV7NlF0g1p"
                                                    @"Zv9qQGcvlJ52hLRJg/Q/xJqlspYYR7/sVbfKUwIDAQABo4IBtDCCAbAwDwYDVR0T"
                                                    @"AQH/BAUwAwEBADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDgYDVR0P"
                                                    @"AQH/BAQDAgWgMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwuZ29kYWRkeS5j"
                                                    @"b20vZ2RpZzJzMS00MC5jcmwwUwYDVR0gBEwwSjBIBgtghkgBhv1tAQcXATA5MDcG"
                                                    @"CCsGAQUFBwIBFitodHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3JlcG9z"
                                                    @"aXRvcnkvMHYGCCsGAQUFBwEBBGowaDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au"
                                                    @"Z29kYWRkeS5jb20vMEAGCCsGAQUFBzAChjRodHRwOi8vY2VydGlmaWNhdGVzLmdv"
                                                    @"ZGFkZHkuY29tL3JlcG9zaXRvcnkvZ2RpZzIuY3J0MB8GA1UdIwQYMBaAFEDCvSeO"
                                                    @"zDSDMKIz1/tss/C0LIDOMCkGA1UdEQQiMCCCDyouc2ltcGVyaXVtLmNvbYINc2lt"
                                                    @"cGVyaXVtLmNvbTAdBgNVHQ4EFgQUp3x7b7MWkWGHlTN5E5bu44f4el4wDQYJKoZI"
                                                    @"hvcNAQELBQADggEBAFpa/L/n1GuOVs9kO9FYloFo7VnIkhhiiY1ExR2R5O+8K70K"
                                                    @"ycKgGhy5qGiKIXRBl/WO4FSLI5nEaNh1x2JZR4DTfslrZji6ZfIn2gWFXVaq4xpZ"
                                                    @"sZYWC8gr5k1FrGDYe+WkolbkVItn/10jD/IRILjodwfCRMhxd81BZOOFBfVjndPd"
                                                    @"3TFo3Yyr+a8jdjgfEbhdFl+TsSXdLhFgSPla9iWXGLM62xV9wvL6kYEjORO5EaQs"
                                                    @"InaPsgGNnQlmjma1aTseqNvyFTqnGydI9nFvcrbA0zDAMHwojL8ucShEfZZuE4cw"
                                                    @"1VSes+bqjqfqLlWitfhe1Q6loHgn6AeKG68JC0Y=";
