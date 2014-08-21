#import <Foundation/Foundation.h>

#if 0

	Scenario  Swizzle Technology                Method Implementation  Correct Behavior  10.4  64-bit
	========  ================================  =====================  ================  ====  ======
		   1  Classic                           Direct                 YES               YES   NO
		   2  Classic                           Inherited              NO                YES   NO
		   3  Ballard                           Direct                 YES               YES   NO
		   4  Ballard                           Inherited              YES               YES   NO
		   5  method_exchangeImplementations    Direct                 YES               NO    YES
		   6  method_exchangeImplementations    Inherited              NO                NO    YES
		   7  +swizzleMethod:withMethod:error:  Direct                 YES               YES   YES
		   8  +swizzleMethod:withMethod:error:  Inherited              YES               YES   YES

	* build+test 10.3 ppc (1, 2, 3, 4, 7, 8)
	* build+test 10.4 ppc + i386 (1, 2, 3, 4, 7, 8)
	* build+test 10.5 32-bit ppc + i386 (1, 2, 3, 4, 5, 6, 7, 8)
	* build+test 10.5 64-bit x86_64 + ppc64 (5, 6, 7, 8)

#endif

int main (int argc, const char * argv[]) {
	BOOL sixty_four_bit;
#ifdef __LP64__
	sixty_four_bit = YES;
#else
	sixty_four_bit = NO;
#endif
	
	printf("JRSwizzleTest success SDK:%d %s\n", MAC_OS_X_VERSION_MAX_ALLOWED, sixty_four_bit ? "64-bit" : "32-bit");
    return 0;
}