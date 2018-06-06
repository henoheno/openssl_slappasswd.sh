#!/bin/sh
# test script for openssl_slappasswd.sh
#

# ----------------------------------------

assertequals()
{
  title="$1"
  expected="$2"
  actual="$3"
  message="$*"
  if [ "x$expected" = "x$actual" ]
    then echo "ok: $title $expected"
    else echo "NG: $title expected: $expected but was: $actual"
  fi
}

# ----------------------------------------
title='Exclusive options: Salt from'

_test()
{
  ./openssl_slappasswd.sh --debug --scheme smd5 --secret s "$@" 2>&1 |
     grep Salt: | cut -d ' ' -f 3
}
assertequals "$title" '--salt'        "` _test --salt-file ./README.txt --salt-random 1 --salt s `"
assertequals "$title" '--salt-random' "` _test --salt s --salt-file ./README.txt --salt-random 1 `"
assertequals "$title" '--salt-file'   "` _test --salt-random 1 --salt s --salt-file ./README.txt `"
assertequals "$title" '--scheme'      "` _test --scheme '{SMD5}hash' --salt-file ./README.txt --salt-random 1 --salt s `"
assertequals "$title" '--salt'        "` _test --scheme '{SMD5}'     --salt-file ./README.txt --salt-random 1 --salt s `"

# ----------------------------------------
# Hash verifications

_test()
{
  scheme="$1"
  assertequals "$title" "$scheme" \
    "` ./openssl_slappasswd.sh --secret "$secret" --scheme "$scheme" -n `"
}

title=openssl_slappasswd.sh
secret=openssl_slappasswd.sh
_test '{SSHA256}X+HzDQwq/VcOUctD7+FxvGDyCFDmiW6TQvblYJuCBlp4qlJ2GFKNPw=='
_test '{SSHA384}/0PuiFKwMu6qDH65znVfwmheUB0z9z+pd+MvjTD9kSXKIzoU2tck5d1Eo0dim6Vs8Fdnaq6TlXg='
_test '{SSHA512}5AxKHK/q36t0ozC/hJCDYjnK0I4kwnTS/JkA1UisIVycgDbDfdAIqvan0w5QZN5iSnofINUp+9/kHhktIwgEozDcHcJXAo5V'

# https://github.com/openldap/openldap/tree/master/contrib/slapd-modules/passwd/sha2/README
title='contrib/slapd-modules/passwd/sha2/README'
secret=secret
_test '{SHA512}vSsar3708Jvp9Szi2NWZZ02Bqp1qRCFpbcTZPdBhnWgs5WtNZKnvCXdhztmeD2cmW192CF5bDufKRpayrW/isg=='
_test '{SHA384}WKd1ukESvjAFrkQHznV9iP2nHUBJe7gCbsrFTU4//HIyzo3jq1rLMK45dg/ufFPt'
_test '{SHA256}K7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol/pe/Unols='

title=slappasswd-static
secret=slappasswd-static
_test '{MD5}9f8PcTTi+T+5ub5eX9R6JQ=='
_test '{SMD5}ZrpmHLhMSAl6xoGV1TH1dgWoMz4='
_test '{SHA}GgPbiGekbxc9A1zlpk7rBB2k+3Y='
_test '{SSHA}KBQva9lOc2j6X2oo8bGgbZtjkcpJBWlz'
_test '{SHA256}Wwkmxpl01zo7MwRdtt4fCiVDd86h1otGm9ADF/Mc6oI='
_test '{SHA384}DI4ORkzsuykiGwDhPk78h/6Lzs6syzeIz2q23e1i5ZEQnZR6tbGZUjC3d1Za4OxT'
_test '{SHA512}pnvx1FlNK39PbQ7un1LRu3zeiuN3NaS/3zKxumpoiFS5S4m5AKcqDrTKtx0j/Ado6nwNQb9Ly73r/4+fMv/KRw=='
_test '{SSHA256}XKnGee0csI1FNLTZdIjhXgLR690UJv9XSfVozYQLgRIfHbi5EkrPaA=='
_test '{SSHA384}lqwDJ57bh4yXnb7ED+l2mS74Vm8PgJZK1VlcUi7CypJLujqwFjpvqNdQTpttPJ0wrW4JbsugjuI='
_test '{SSHA512}sQMko4CUJKuwQyY9cqJdghty4GdsZXJGniXa/aIu67ACT1k49xuXqkMXvO8cE5VpfmB8Be073gKbc/4/KhXlinzFVlNtgNRx'

title=slappasswd-dynamic
secret=slappasswd-dynamic
alias slappasswd="slappasswd -o module-path=/usr/lib64/openldap -o module-load=pw-sha2" # CentOS 7
_test "` slappasswd -h '{MD5}'     -s "$secret" `"
_test "` slappasswd -h '{SMD5}'    -s "$secret" `"
_test "` slappasswd -h '{SSHA}'    -s "$secret" `"
_test "` slappasswd -h '{SSHA}'    -s "$secret" `"
_test "` slappasswd -h '{SHA256}'  -s "$secret" `"
_test "` slappasswd -h '{SHA384}'  -s "$secret" `"
_test "` slappasswd -h '{SHA512}'  -s "$secret" `"
_test "` slappasswd -h '{SSHA256}' -s "$secret" `"
_test "` slappasswd -h '{SSHA384}' -s "$secret" `"
_test "` slappasswd -h '{SSHA512}' -s "$secret" `"

# ----------------------------------------
