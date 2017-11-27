if [ $# -ne 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: prs.sh source_branch destination_branch"
    echo "example: prs.sh release/8.7 release/8.8"
    exit -1;
fi

source_branch="$1"
destination_branch="$2"

for pr in `git log --pretty=oneline $source_branch..$destination_branch | grep -Eo '#\d+' | tr -d '#'`; do curl -s https://api.github.com/repos/wordpress-mobile/WordPress-iOS/pulls/$pr | jq -r '"#\(.number): \(.title) @\(.user.login) \(.html_url)"'; done
