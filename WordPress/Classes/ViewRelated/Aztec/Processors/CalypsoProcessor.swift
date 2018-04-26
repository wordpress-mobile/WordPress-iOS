import Aztec
import Foundation

protocol CalypsoProcessor: Processor {
}

extension CalypsoProcessor {
    
    /// HACK: not a very good approach, but our APIs don't offer proper versioning info on `post_content`.
    /// Directly copied from here: https://github.com/WordPress/gutenberg/blob/5a6693589285363341bebad15bd56d9371cf8ecc/lib/register.php#L343
    ///
    func wasWrittenWithGutenberg(_ content: String) -> Bool {
        return content.contains("<!-- wp:")
    }
}
