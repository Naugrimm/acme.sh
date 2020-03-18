#!/usr/bin/env sh

#acme.sh dns securepoint

SP_Api="https://api.spdyn.de/api/3"

########  Public functions #####################

#Usage: add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_sp_add() {
  fulldomain=$1
  txtvalue=$2

  SP_Key="${SP_Key:-$(_readaccountconf_mutable SP_Key)}"

  if [ -z "$SP_Key" ]; then
    SP_Key=""
    _err "You don't specify spdyn api key yet."
    _err "Please create your key and try again."
    return 1
  fi

  _saveaccountconf_mutable SP_Key "$SP_Key"

  _info "Using securepoint api"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  _info "Adding record"
  if _sp_rest POST "host/acmeChallenge" "{\"host\":\"$fulldomain\",\"challengeToken\":\"$txtvalue\"}"; then
    if printf -- "%s" "$response" | grep "$fulldomain" >/dev/null; then
      _info "Added, OK"
      return 0
    else
      _err "Add txt record error."
      return 1
    fi
  fi
  _err "Add txt record error."
  return 1
}

#Usage: fulldomain txtvalue
#Remove the txt record after validation.
dns_sp_rm() {
  fulldomain=$1
  txtvalue=$2

  SP_Key="${SP_Key:-$(_readaccountconf_mutable SP_Key)}"

  if [ -z "$SP_Key" ]; then
    SP_Key=""
    _err "You don't specify spdyn api key yet."
    _err "Please create your key and try again."
    return 1
  fi

  _saveaccountconf_mutable SP_Key "$SP_Key"

  _info "Using securepoint api"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  if ! _sp_rest DELETE "host/acmeChallenge" "{\"host\":\"$fulldomain\",\"challengeToken\":\"$txtvalue\"}"; then
    _err "Delete record error."
    return 1
  fi
  _contains "$response" '"success":true'
}

####################  Private functions below ##################################
_sp_rest() {
  method=$1
  endpoint="$2"
  data="$3"
  _debug "$endpoint"

  export _H1="Authorization: Bearer $SP_Key"
  export _H2="Content-Type: application/json"

  if [ "$method" != "GET" ]; then
    _debug data "$data"
    response="$(_post "$data" "$SP_Api/$endpoint" "" "$method" "application/json")"
  else
    response="$(_get "$SP_Api/$endpoint")"
  fi

  if [ "$?" != "0" ]; then
    _err "error $endpoint"
    return 1
  fi
  _debug2 response "$response"
  return 0
}
