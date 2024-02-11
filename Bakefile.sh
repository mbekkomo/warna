#!/usr/bin/env bash

# shellcheck disable=SC2155

# genrelease <{'revision','patch','minor','major'}> [push-tags]
task.genrelease() {
  local tags="$(git tag --sort=version:refname)"
  local tag_latest="$(tail -n 1 <<< "$tags")"

  if [[ -z "$tag_latest" ]]; then
    tag_latest="v0.0.0-1"
  fi

  tag_latest="${tag_latest#v}"

  local type="${1-}" version_next

  case "$type" in
    revision) version_next="$(awk -F- '{$2++; print $1"-"$2}' <<< "$tag_latest")" ;;
    patch) version_next="$(awk -F. '{$NF++; print $1"."$2"."$NF"-1"}' <<< "$tag_latest")" ;;
    minor) version_next="$(awk -F. '{$2++; $3=0; print $1"."$2"."$3"-1"}' <<< "$tag_latest")" ;;
    major) version_next="$(awk -F. '{$1++; $2=0; $3=0; print $1"."$2"."$3"-1"}' <<< "$tag_latest")" ;;
    *) bake.die "expected 'revision', 'patch', 'minor', 'major'. got '$type'" ;;
  esac

  ./luarocks lint ./warna-dev-1.rockspec

  rockspec="$(< ./warna-dev-1.rockspec)"
  rockspec="${rockspec//local _version/local _version = \"$version_next\"}"
  echo "$rockspec" > "warna-$version_next.rockspec"

  git tag -a "v$version_next" -m "Release: v$version_next"

  [[ -n "$2" ]] && git push origin main --follow-tags
  return 0
}

# format
task.format() {
  stylua . ./*.rockspec
  while read -r f; do
    shfmt -w "$f"
  done < <(find . -name '*.sh' -not -path 'lua_modules')
}
