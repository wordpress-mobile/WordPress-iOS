# NSObject+SafeExpectations
No more crashes getting unexpected values from a `NSDictionary`.

## Usage

There are a few new methods available for a `NSDictionary`: see the [documentation](http://koke.github.com/NSObject-SafeExpectations/Categories/NSDictionary+SafeExpectations.html)

- (NSString *)stringForKey:(id)key;
- (NSNumber *)numberForKey:(id)key;
- (NSArray *)arrayForKey:(id)key;
- (NSDictionary *)dictionaryForKey:(id)key;
- (id)objectForKeyPath:(NSString *)keyPath;
- (NSString *)stringForKeyPath:(id)keyPath;
- (NSNumber *)numberForKeyPath:(id)keyPath;
- (NSArray *)arrayForKeyPath:(id)keyPath;
- (NSDictionary *)dictionaryForKeyPath:(id)keyPath;


## Wishlist
* `NSArray`: `stringAtIndex:`, `numberAtIndex:`, `arrayAtIndex:`, `dictionaryAtIndex:`
* Collections support for `objectForKeyPath:`