#!/bin/sh
#
#  openssl_slappasswd -- OpenLDAP slappasswd(with pw-sha2)-compatible
#  hash generator and checker, only with openssl and shellscript
#  ==========================================================
   Copyright='(C) 2018 henoheno@users.osdn.me'
   Homepage='https://ja.osdn.net/users/henoheno/'
   License='The OpenLDAP Public License, and revised BSD License'
#
#  ( Test environment: CentOS Linux 7 with openssl )

# Software versioning
VERS_major='0'         # User Interface (file-name etc.) are holded
VERS_minor='9.4'       # Release / build number
VERSION="$VERS_major.$VERS_minor"

# Name and Usage --------------------------------------------
ckname="` basename -- "$0" `"

usage(){
  trace 'usage()' || return  # (DEBUG)
   warn "$ckname -- OpenLDAP slappasswd(with pw-sha2)-compatible"
   warn 'hash generator and checker, only with openssl and shellscript'
  qwarn
  qwarn "Usage: $ckname [-h|--scheme scheme]"
  qwarn '       [-s|--secret secret]        [--salt salt]'
  qwarn '       [-T|--secret-file filepath] [--salt-file filepath]'
  qwarn '       [--salt-random N] [-n]'
  qwarn
  qwarn "  -h 'scheme', --scheme 'scheme'"
  qwarn '        scheme(password hash scheme):'
  qwarn '            md5,  sha,  sha256,  sha384,  sha512,'
  qwarn '           smd5, ssha, ssha256, ssha384, ssha512,'
  qwarn "            '{MD5}',  '{SHA}',  '{SHA256}',  '{SHA384}',  '{SHA512}',"
  qwarn "           '{SMD5}', '{SSHA}', '{SSHA256}', '{SSHA384}', '{SSHA512}'"
  qwarn "           (default: '{SSHA256}')"
  qwarn
  qwarn "  -s 'secret', --secret 'secret'"
  qwarn '        passphrase or secret'
  qwarn "  -T 'filepath', --secret-file 'filepath'"
  qwarn '        use entire file content for secret'
  qwarn
  qwarn "  --salt 'salt'"
  qwarn '        specify salt text for smd5, ssha, ssha256, ssha384, ssha512'
  qwarn "  --salt-file 'filepath'"
  qwarn '        use entire file content for salt'
  qwarn '  --salt-random N|NN|NNN|NNNN'
  qwarn '        specify random salt length (default:8 bytes)'
  qwarn "  --scheme '{SCHEME}base64-encoded-hash-and-salt'"
  qwarn '        specify salt'
  qwarn
  qwarn '  -n    omit trailing newline'
  qwarn
  qwarn "  -h       '{SCHEME}base64-encoded-hash-and-salt',"
  qwarn "  --scheme '{SCHEME}base64-encoded-hash-and-salt'"
  qwarn "        verify userPassword and return true if that seems verified"
  qwarn "        with the secret and salt"
  qwarn
  qwarn 'Examples:'
  qwarn "  $ $ckname --secret pass --scheme ssha256"
  qwarn '  {SSHA256}10/w7o2juYBrGMh32/KbveULW9jk2tejpyUAD+uC6PE= # random salt'
  qwarn "  $ $ckname --secret pass --scheme ssha256 --salt 'foobar' # specify salt from --salt"
  qwarn '  {SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI='
  qwarn "  $ $ckname --secret pass --scheme '{SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI='"
  qwarn '  {SSHA256}Yuz0lZnd9xxLQhxgOSuV8b4GlTzeOWKriq9ay51aoLxmb29iYXI= # specify salt from data, verify OK'
  qwarn ; return 1
}

# Common functions ------------------------------------------
warn(){  echo "$*" 1>&2 ; }
qwarn(){ test "$__quiet"   || warn "$*" ; }
qecho(){ test "$__quiet"   || echo "$*" ; }
vwarn(){ test "$__verbose" && warn "$*" ; }
vecho(){ test "$__verbose" && echo "$*" ; }
dwarn(){ test "$__debug"   && warn "$*" ; }
decho(){ test "$__debug"   && echo "$*" ; }
err() {  warn "Error: $*" ; exit 1 ; }

quote(){
  test    $# -gt 0  && {  echo -n  "\"$1\"" ; shift ; }
  while [ $# -gt 0 ] ; do echo -n " \"$1\"" ; shift ; done ; echo
}

trace(){
  test "$__debug" || return 0  # (DEBUG)
  _msg="$1" ; test $# -gt 0 && shift ; warn "  $_msg    : ` quote "$@" `"
}

version(){
  trace 'version()' || return  # (DEBUG)
  warn ; warn "$ckname $VERSION" ; warn "Copyright $Copyright"
  warn "$Homepage" ; warn "License: $License" ; warn ; return 1
}

# Prerequisites ---------------------------------------------

# openssl commnad

# Default variables -----------------------------------------

# Function verifying arguments ------------------------------

# _NOP = Do nothing (No operation)
getopt(){ _arg=noarg
  trace 'getopt()' "$@"  # (DEBUG)

  case "$1" in
  ''  )  echo 1 ;;

  # Grobal and Local options for slappasswd
  -h|--sc|--sch|--sche|--schem|--scheme        ) echo _scheme 2 ; _arg="ALLOWEMPTY" ;;
  -s|--se|--sec|--secr|--secr|--secre|--secret ) echo _secret 2 ; _arg="$2" ;;
  -T|--fi|--fil|--file|--secret-f|--secret-fi|--secret-fil|--secret-file )
    echo _file 2 ; _arg="$2" ;;
  --salt-f|--salt-fi|--salt-fil|--salt-file ) echo _sfile 2 ; _arg="$2" ;;
  --salt-r|--salt-ra|--salt-ran|--salt-rand|--salt-rando|--salt-random )
    echo _srand 2; _arg="$2" ;;
  -n|--omit-the-trailing-newline ) echo _nonewline ;;

   # Do nothing, compatibility only
  -u|--userPassword      ) echo _NOP ;;
  -o|--option            ) echo _NOP 2 ; _arg="$2" ;;

  # Not supported
  #-c|--crypt-salt-format ) echo _NOP 2 ; _arg="$2" ;;
  # slappasswd seems not work for SHA-2
  #-g|--gen|--gene|--gener|--generate ) echo _NOP ;;

  # Original options
  # Salt not from with scheme
  --sa|--sal|--salt ) echo _salt 2 ; _arg="$2" ;;

  # Common options
  -[hH]|--he|--help ) echo _usage exit1 ;;
     --vers|--versi|--versio|--version ) echo _version exit1 ;;
  -v|--verb|--verbo|--verbos|--verbose ) echo _verbose ;;
  -q|--qu|--qui|--quiet        ) echo _quiet ;;
  -f|--fo|--for|--forc|--force ) echo _force ;;
     --de|--deb|--debu|--debug ) echo _debug ;;

  -*  ) warn "Error: Unknown option \"$1\"" ; return 1 ;;

  # No commands
   *  ) echo _usage exit1 ;;
  esac

  test 'x' != "x$_arg"
}

preparse_single_options(){
  while [ $# -gt 0 ] ; do
    chs="` getopt "$@" 2> /dev/null `"
    for ch in $chs ; do
      case "$ch" in
        _* ) echo "_$ch" ;;
      esac
    done
    shift
  done
}

# Working start ---------------------------------------------

# Show arguments in one line (DEBUG)
case '--debug' in "$1"|"$3") false ;; * ) true ;; esac || {
  test 'x--debug' = "x$1" && shift ; __debug=on ; trace 'Args  ' "$@"
}

# No argument (slappasswd compatible way)
if [ $# -eq 0 ] ; then
  _scheme= ; _secret= ; _salt= ; _file= ; _sfile=
fi

# Preparse
for i in ` preparse_single_options "$@" ` ; do
  eval "$i=on"
done

# Parse
while [ $# -gt 0 ] ; do
  chs="` getopt "$@" `" || { warn "Syntax error with '$1'" ; usage; exit 1 ; }
  trace '$chs  ' "$chs"  # (DEBUG)

  for ch in $chs ; do
  case "$ch" in
   ## Single options
    _usage   ) usage     ;;
    _version ) version   ;;

   ## Double Options
   _scheme ) _scheme="$2" ;;

   _secret ) _secret="$2" ; _file=   ;; # Exclusive
   _file   ) _file="$2"   ; _secret= ;; # _secret or _file

   _salt   ) _salt="$2"   ; _sfile=  ; _srand= ;; # Exclusive
   _sfile  ) _sfile="$2"  ; _salt=   ; _srand= ;; # _salt or _sfile or _srand
   _srand  ) _srand="$2"  ; _sfile=  ; _salt=  ;; #

   _*      ) shift ;; ## Preparsed or NOP

   ## Commands
   [1-3]     ) shift $ch ;;
   exit      ) exit      ;;
   exit1     ) exit 1    ;;
   * )
      if [ -z "$__help" ]
      then err "Unknown command \"$1\""
      else err "Unknown command \"$2\""
      fi
  esac
  done
done

# No secret
if [ 'x' = "x$_secret$_file" ] ; then
  echo -n 'New password: '          1>&2 ; read    _secret
  echo -n 'Re-enter new password: ' 1>&2 ; read -s _secret2
  echo
  if [ 'x' = "x$_secret" ] ; then
    warn 'Password verification failed.'
    usage
    exit 1
  fi
  if [ "x$_secret" != "x$_secret2" ] ; then
    warn 'Password values do not match'
    usage
    exit 1
  fi
fi


# Working start ---------------------------------------------

_openssl_slappasswd()
{
  if [ 'x' != "$__debug" ]
  then base='_openssl_slappasswd(): '
  else base=
  fi
  warn(){  echo "$base$*" 1>&2 ; }
  dwarn(){ test 'x' != "x$__debug"   && warn "$*" ; }

  # Prerequisites: openssl command
  for target in openssl sed tail ; do
    if ! which "$target" 1>/dev/null 2>&1 ; then
      warn "Command not found: $target" ; exit 1
    fi
  done

  scheme="$1"
  secret="$2"
  salt="$3"
  file="$4"
  sfile="$5"
  srand="$6"
  case "$scheme" in
    '{'[a-zA-Z0-9./_-][a-zA-Z0-9./_-]*'}'* )
      scheme="` echo "$1" | sed 's#^\({[a-zA-Z0-9./_-][a-zA-Z0-9./_-]*}\).*#\1#' | tr A-Z a-z | tr -d '{}' `"
      hash="`   echo "$1" | sed   's#^{[a-zA-Z0-9./_-][a-zA-Z0-9./_-]*}##' `"
    ;;
    * )
      scheme="` echo "$1" | tr A-Z a-z `"
      hash=
    ;;
  esac
  if [ 'x' != "x$__debug" ] ; then
    warn "scheme=$scheme"
    warn "hash=$hash"
    warn "secret=$secret"
    warn "file=$file"
    warn "salt=$salt"
    warn "sfile=$sfile"
    warn "srand=$srand"
  fi

  algo= ; l= ; prefix=
  case "$scheme" in
    ''      ) algo='-sha256'; l=33; prefix='{SSHA256}'; scheme=ssha256 ;;
    ssha256 ) algo='-sha256'; l=33; prefix='{SSHA256}';;
     sha256 ) algo='-sha256'; l=  ; prefix='{SHA256}' ;;
    ssha384 ) algo='-sha384'; l=49; prefix='{SSHA384}';;
     sha384 ) algo='-sha384'; l=  ; prefix='{SHA384}' ;;
    ssha512 ) algo='-sha512'; l=65; prefix='{SSHA512}';;
     sha512 ) algo='-sha512'; l=  ; prefix='{SHA512}' ;;
       ssha ) algo='-sha1'  ; l=21; prefix='{SSHA}'   ;; # Not -sha
        sha ) algo='-sha1'  ; l=  ; prefix='{SHA}'    ;; # Not -sha
       smd5 ) algo='-md5'   ; l=17; prefix='{SMD5}'   ;;
        md5 ) algo='-md5'   ; l=  ; prefix='{MD5}'    ;;
    * ) warn "Non-supported scheme: $scheme" ; return 1 ;;
  esac

  case "$srand" in
    [0-9] | [0-9][0-9] | [0-9][0-9][0-9] | [0-9][0-9][0-9][0-9] ) ;; # 0000 seems OK
    *  ) srand=8 ;;
  esac

  # <- Binary-friendry way but maybe slow:
  #    You know if your /tmp is on the memory or not
  tmp_header="/tmp/tmp_$$_` openssl rand -hex 15 `"
  tmp_payload="${tmp_header}_payload.bin"
     tmp_salt="${tmp_header}_salt.bin"
  trap 'rm -f "$tmp_payload" "$tmp_salt"' 1 3 4 6 10 15

  case "$scheme" in
    ssha* | smd5* )
      if [ 'xx' != "x${salt}x" ]
      then
        dwarn "Salt: --salt '$salt'"
        echo -n "$salt"  > "$tmp_salt"
        sfile="$tmp_salt"
      else
        if [ 'x' != "x$sfile" -a -f "$sfile" ]
        then
          dwarn "Salt: --salt-file '$sfile'"
        else
          if [ 'xx' != "x${hash}x" ]
          then
            dwarn "Salt: from hash"
             echo -n "$hash" | openssl enc -d -base64 -A | tail -c "+$l" >  "$tmp_salt" # [O]
            #echo -n "$hash" | openssl enc -d -base64 -A | cut  -b "$l-" >  "$tmp_salt" # [X]
          else
            dwarn "Salt: random $srand bytes"
            openssl rand "$srand" > "$tmp_salt"
          fi
          sfile="$tmp_salt"
        fi
      fi
    ;;
  esac

  if [ 'x' = "x$file" -o ! -f "$file" ] ; then
    echo -n "$secret" > "$tmp_payload"
    file="$tmp_payload"
  fi

  echo -n "$prefix"

  openssl_file2hash(){
    algo="$1" ; shift
    sfile="$2" # salt.bin
    if [ 'x' = "x$sfile" -o ! -f "$sfile" ]
    then cat "$@" | openssl dgst "$algo" -binary | openssl enc -base64 -A
    else cat "$@" | openssl dgst "$algo" -binary |
                                 cat - "$sfile" | openssl enc -base64 -A
    fi
  }
  case "$scheme" in
    ssha* | smd5* ) openssl_file2hash "$algo" "$file" "$sfile" ;;
    *             ) openssl_file2hash "$algo" "$file"          ;;
  esac

  rm -f "$tmp_payload" "$tmp_salt"
  # -> Binary-friendry way
}

result="` _openssl_slappasswd "$_scheme" "$_secret" "$_salt" "$_file" "$_sfile" "$_srand" `" && {
  if [ "$__nonewline" ]
    then echo -n "$result"
    else echo    "$result"
  fi
  test "x$_scheme" = "x$result"
}
