openssl_slappasswd.sh -- OpenLDAP slappasswd(with pw-sha2)-compatible
hash generator and checker, only with openssl and shellscript

Usage: openssl_slappasswd.sh [-h|--scheme scheme]
       [-s|--secret secret]        [--salt salt]
       [-T|--secret-file filepath] [--salt-file filepath]
       [--salt-random N] [-n]

  -h 'scheme', --scheme 'scheme'
        scheme(password hash scheme):
            md5,  sha,  sha256,  sha384,  sha512,
           smd5, ssha, ssha256, ssha384, ssha512,
            '{MD5}',  '{SHA}',  '{SHA256}',  '{SHA384}',  '{SHA512}',
           '{SMD5}', '{SSHA}', '{SSHA256}', '{SSHA384}', '{SSHA512}'
           (default: '{SSHA256}')

  -s 'secret', --secret 'secret'
        passphrase or secret
  -T 'filepath', --secret-file 'filepath'
        use entire file content for secret

  --salt 'salt'
        specify salt text for smd5, ssha, ssha256, ssha384, ssha512
  --salt-file 'filepath'
        use entire file content for salt
  --salt-random N|NN|NNN|NNNN
        specify random salt length (default:8 bytes)
  --scheme '{SCHEME}base64-encoded-hash-and-salt'
        specify salt

  -n    omit trailing newline

  -h       '{SCHEME}base64-encoded-hash-and-salt',
  --scheme '{SCHEME}base64-encoded-hash-and-salt'
        verify userPassword and return true if that seems verified
        with the secret and salt

Examples:
  $ openssl_slappasswd.sh --secret pass --scheme ssha256
  {SSHA256}10/w7o2juYBrGMh32/KbveULW9jk2tejpyUAD+uC6PE= # random salt
  $ openssl_slappasswd.sh --secret pass --scheme ssha256 --salt 'foobar' # specify salt from --salt
  {SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI=
  $ userPassword='{SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI='
  $ openssl_slappasswd.sh --secret pass  --scheme "$userPassword" && echo OK
  {SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI=
  OK
  $ openssl_slappasswd.sh --secret WRONG --scheme "$userPassword" || echo NG
  {SSHA256}OlNVHPhhfEcyhyVnMvM3WJuMLi8ogLZJAYpqPThS+/Zmb29iYXI=
  NG

