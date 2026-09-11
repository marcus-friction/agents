# Source this helper before writing private artifacts or executing installed code.
# Same-user hostile mutation is outside the cooperative installer contract.
require_trusted_parent() {
  local current="$1" child="" uid mode permissions owner root_owner
  uid="$(id -u)"
  root_owner="$(stat -c '%u' / 2>/dev/null || stat -f '%u' /)"
  while :; do
    [ ! -L "$current" ] && [ -d "$current" ] || {
      echo "Error: private destination crosses an unsafe directory: $current" >&2; return 1;
    }
    owner="$(stat -c '%u' -- "$current" 2>/dev/null || stat -f '%u' "$current")"
    mode="$(stat -c '%a' -- "$current" 2>/dev/null || stat -f '%Lp' "$current")"
    permissions=$((8#$mode))
    [ "$owner" = "$uid" ] || [ "$owner" = "$root_owner" ] || {
      echo "Error: private destination has a foreign-owned ancestor: $current" >&2; return 1;
    }
    if [ $((permissions & 0022)) -ne 0 ]; then
      # Sticky system roots protect caller-owned children; callers create new
      # children exclusively and validate ownership before accepting old ones.
      [ "$owner" = "$root_owner" ] && [ $((permissions & 01000)) -ne 0 ] || {
        echo "Error: private destination has a writable ancestor: $current" >&2; return 1;
      }
    fi
    [ "$current" != / ] || break
    child="$current"
    current="$(dirname "$current")"
  done
}
