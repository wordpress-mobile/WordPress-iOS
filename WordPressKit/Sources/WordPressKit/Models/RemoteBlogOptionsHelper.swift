import Foundation

@objcMembers public class RemoteBlogOptionsHelper: NSObject {

    public class func mapOptions(fromResponse response: NSDictionary) -> NSDictionary {
        let options = NSMutableDictionary()
        options["home_url"] = response["URL"]
        if response.number(forKey: "jetpack")?.boolValue == true {
            options["jetpack_client_id"] = response.number(forKey: "ID")
        }
        if response["options"] != nil {
            options["post_thumbnail"] = response.value(forKeyPath: "options.featured_images_enabled")

            let optionsDirectMapKeys = [
                "active_modules",
                "admin_url",
                "login_url",
                "unmapped_url",
                "image_default_link_type",
                "software_version",
                "videopress_enabled",
                "timezone",
                "gmt_offset",
                "allowed_file_types",
                "frame_nonce",
                "jetpack_version",
                "is_automated_transfer",
                "blog_public",
                "max_upload_size",
                "is_wpcom_atomic",
                "is_wpforteams_site",
                "show_on_front",
                "page_on_front",
                "page_for_posts",
                "blogging_prompts_settings",
                "jetpack_connection_active_plugins",
                "can_blaze"
            ]
            for key in optionsDirectMapKeys {
                if let value = response.value(forKeyPath: "options.\(key)") {
                    options[key] = value
                }
            }
        }
        let valueOptions = NSMutableDictionary(capacity: options.count)
        for (key, obj) in options {
            valueOptions[key] = [
                "value": obj
            ]
        }

        return NSDictionary(dictionary: valueOptions)
    }

    // Helper methods for converting between XMLRPC dictionaries and RemoteBlogSettings
    // Currently, we are only ever updating the blog title or tagline through XMLRPC
    // Brent - Jan 7, 2017
    public class func remoteOptionsForUpdatingBlogTitleAndTagline(_ blogSettings: RemoteBlogSettings) -> NSDictionary {
        let options = NSMutableDictionary()
        if let value = blogSettings.name {
            options["blog_title"] = value
        }
        if let value = blogSettings.tagline {
            options["blog_tagline"] = value
        }
        return options
    }

    public class func remoteBlogSettings(fromXMLRPCDictionaryOptions options: NSDictionary) -> RemoteBlogSettings {
        let remoteSettings = RemoteBlogSettings()
        remoteSettings.name = options.string(forKeyPath: "blog_title.value")?.stringByDecodingXMLCharacters()
        remoteSettings.tagline = options.string(forKeyPath: "blog_tagline.value")?.stringByDecodingXMLCharacters()
        if options["blog_public"] != nil {
            remoteSettings.privacy = options.number(forKeyPath: "blog_public.value")
        }
        return remoteSettings
    }

}
