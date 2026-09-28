import Foundation

/// Metni POSIX kabuğu için tek tırnakla güvenli biçimde alıntılar; `$`, `` ` ``, `;` gibi karakterler yorumlanmaz.
public func shellQuoted(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
}
