#!/bin/bash
[[ $(pwd) == $(dirname $(readlink -f $0)) ]] || {
	>&2 echo You need to run this script from its directory.
	exit 1
}
crystal run src/pathfind.cr -- $@
