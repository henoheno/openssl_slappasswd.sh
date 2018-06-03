openssl_slappasswd.sh -- OpenLDAP slappasswd(with pw-sha2)-compatible
                hash generator only with openssl and shellscript

Usage: openssl_slappasswd.sh [-h|--scheme scheme] [-s|--secret secret]
       [--salt salt] [-T|--file filepath] [-n]

  -h scheme, --scheme scheme
        scheme(password hash scheme):
           md5,  sha1,  sha256,  sha384,  sha512,
           smd5, ssha1, ssha256, ssha384, ssha512,
           {MD5},  {SHA1},  {SHA256},  {SHA384},  {SHA512},
           {SMD5}, {SSHA1}, {SSHA256}, {SSHA384}, {SSHA512}
           (default: '{SSHA256}')
           You can put '{SCHEME}base64-encoded-hash-and-salt' to verify

  -s secret, --secret secret
        passphrase or secret

  -T filepath, --file filepath
        use entire file contents for secret

  --salt salt
        specify salt for smd5, ssha1, ssha256, ssha384, ssha512
        (default: random 8 bytes)

  -n    omit trailing newline

Examples:
  $ openssl_slappasswd.sh --secret pass --scheme ssha256
  {SSHA256}10/w7o2juYBrGMh32/KbveULW9jk2tejpyUAD+uC6PE= # random salt
  $ openssl_slappasswd.sh --secret pass --scheme ssha256 --salt 'foobar' # specify salt from --salt
  {SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI=
  $ openssl_slappasswd.sh --secret pass --scheme '{SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI='
  {SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI= # specify salt from data, verify OK

