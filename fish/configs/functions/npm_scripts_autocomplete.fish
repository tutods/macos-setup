function _check_node_package_manager
  if test -e ./yarn.lock
    echo "yarn"
  else if test -e ./pnpm-lock.yaml
    echo "pnpm"
  else if test -e ./package.json
    echo "npm"
  else
    echo "Error: package.json file doesn't exist" 1>&2
    return 1
  end
end

function npm_scripts_autocomplete
  set -l package_manager $(_check_node_package_manager)
  if [ $package_manager ]
    set -l scripts $(jq '.scripts' package.json)
    set -l cmd_prefix $(echo "$package_manager run")
    set -l user_defined_scripts $(echo $scripts | jq -r 'to_entries | .[] | (.key + "\t|\t" + "\"" + .value + "\"")')
    begin 
      printf $cmd_prefix' %s\n' $user_defined_scripts | column -t -s "$(printf '\t')"
    end | fzf -e --info=hidden --prompt "\$ " --height=80% --layout=reverse | awk 'BEGIN {FS="|"}; {print $1}'| awk '{$1=$1};1' | read script
  end
  if [ $script ]
    commandline -r $script
    commandline -f repaint
    commandline -f execute
  else
    commandline -r ''
    commandline -f repaint
  end
end
