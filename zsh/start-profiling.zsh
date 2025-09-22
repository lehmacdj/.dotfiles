zmodload zsh/datetime
setopt PROMPT_SUBST
PS4='+$EPOCHREALTIME %N:%i> '

logfile=$(mktemp zsh_profile.XXXXXXXX)
echo "Profiling to $logfile"
exec 3>&2 2>$logfile

setopt XTRACE
