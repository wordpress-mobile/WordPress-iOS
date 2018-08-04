
class FooterContentGroup: FormattableContentGroup {
    convenience init(blocks: [FormattableContent]) {
        self.init(blocks: blocks, kind: .footer)
    }
}
