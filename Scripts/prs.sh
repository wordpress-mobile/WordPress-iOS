
for pr in `git log --pretty=oneline release/8.7..release/8.8 | grep -Eo '#\d+' | tr -d '#'`; do curl -s https://api.github.com/repos/wordpress-mobile/WordPress-iOS/pulls/$pr | jq -r '"#\(.number): \(.title) @\(.user.login) \(.html_url)"'; done
