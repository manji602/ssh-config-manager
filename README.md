ssh-config-manager
===

## Description

Script for manage .ssh/config with keep idempotence.

## Usage

### Add

```
$ ruby ssh-config-manager.rb --operate add --body "Hosts github.com\n  User git\n..."
```

If you want to add vagrant ssh-config, try this:

```
$ ruby ssh-config-manager.rb --operate add --body "`echo vagrant ssh-config xxx`"
```

If settings of specified host is already written on config, that will be overwritten.

### Fix

```
Host github.com
 User myuser
 port 22
 Hostname github.com
 identityFile ~/.ssh/github_id_rsa
 TCPKeepAlive yes
 IdentitiesOnly yes
```

To fix `User` property, try this:

```
$ ruby ssh-config-manager.rb --operate fix --host "github.com" --key "User" --value "git"
```

Then, settings will be overritten like below:

```
Host github.com
 User git
 port 22
 Hostname github.com
 identityFile ~/.ssh/github_id_rsa
 TCPKeepAlive yes
 IdentitiesOnly yes
```

### Delete

```
$ ruby ssh-config-manager.rb --operate delete --host "github.com"
```

## License

MIT

## Author

[Jun Hashimoto](https://github.com/manji602)
