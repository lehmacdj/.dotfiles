# Starship Configuration
Unfortunately starship doesn't support any kind of shell dependent
configuration so we have to hack it together ourselves. The pattern is to have a
template that we cut up for different shells. Because cutting up files the
size starship.toml is extremely quick, we don't check in the files to git, and
rebuild every time we start the shell.
