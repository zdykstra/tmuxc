# tmuxc

tmuxc attaches to a local or remote tmux session and breaks out each window into a local terminal. Each window in a session is tracked by tmuxc, and when found, a shell script is created that is executed by a terminal of your choice. The shell script creates a new cloned session that's part of the base session you're monitoring, sets a few options, and focuses a specific window.  When that window in tmux is closed, the cloned session is killed, causing the script to finish executing and the terminal to close.

`tmuxc` is written in pure core Perl, so it should work as-is on most any modern system. It's been successfully tested on Void Linux, FreeBSD, OpenBSD, Ubuntu, Arch.

# .tmux.conf changes

A few changes to tmux's configuration will need to be made. Because of the way tmuxc operates, new windows that are created in a session should not automatically get focus. This behavior is nominally controlled by the `-d` flag on new-window and breakp. A full list of changes to .tmux.conf are listed below.

```
# Create a new window, with out focus. This is only needed if you want to use tmux hotkeys to create a window. If you use tmuxc to create a new winodow, this keybind can be left alone.
bind-key c new-window -d

# Break the current pane out into a new window, without focus. There is no tmuxc shortcut for this action.
bind b breakp -d
```

# Configuration file

The tmuxc configuration file is written as an anonymous Perl hash. The syntax is generally easy to pick up - adapting the example listed below to your environment should be a quick process.

Example `~/.config/tmuxc.conf` for a local tmux instance
```
{
  temp         => "$ENV{'XDG_RUNTIME_DIR'}/tmuxc/",
  terminal     => [ qw(kitty) ],
  ssh_args     => [ qw(-A) ],
  selector     => [ 'bemenu -l 10 -i -n -w -P > -p tmuxc --fn "Hack 18"' ],
  input_prompt => [ 'bemenu -l 10 -i -n -w --fn "Hack 18" -p' ],
  session      => 'global-session',
  hosts        =>  {
    localhost => {
      'global-session' => {
        initialize  => [ qw(tmux new-session -d -s global-session) ],
      },
    }, 
  },
}
```


Example `~/.config/tmuxc.conf` for a local and remote tmux instance
```
{
  temp         => "$ENV{'XDG_RUNTIME_DIR'}/tmuxc/",
  terminal     => [ qw(kitty) ],
  ssh_args     => [ qw(-A) ],
  selector     => [ 'bemenu -l 10 -i -n -w -P > -p tmuxc --fn "Hack 18"' ],
  input_prompt => [ 'bemenu -l 10 -i -n -w --fn "Hack 18" -p' ],
  session      => 'global-session',
  hosts        =>  {
    localhost => {
      'global-session' => {
        initialize  => [ qw(tmux new-session -d -s global-session) ],
      },
    },
    'my.remote.server.com' => {
      'global-session' => {
        initialize  => [ qw(tmux new-session -d -s global-session) ],
      },
    }, 
  },
}
```

Example advanced configuration:

```
{
    terminal     => [qw(kitty)],
    session      => 'global-session',
    ssh_args     => [qw(-A -X)],
    selector     => [ qw(bemenu -l 20 -i -n -w -P > -p tmuxc --fn), "Hack 18" ],
    input_prompt => [ qw(bemenu -l 20 -i -n -w --fn), "Hack 18", qw(-p) ],
    temp         => "$ENV{'XDG_RUNTIME_DIR'}/tmuxc/",
    detach       => 0,
    hosts        => {
        localhost => {
            'global-session' => {
                blacklist => ['ignore'],
                initialize =>
                  [qw(tmuxp load -2 -d ~/Documents/global-session.yml)],
            },
            'monitoring' => {
                skipnw     => 1,
                initialize => [qw(tmuxp load -2 -d ~/Documents/monitoring.yml)],
            },
        },
        'irc.vm' => {
            'weechat' => {
                skipnw    => 1,
                blacklist => [ 'ignore', 'top' ],
                initialize =>
                  [qw(/usr/local/bin/tmuxp-3.6 load -2 -d ~/weechat.yml)],
            },
        },
        'bastion.host' => {
            swm              => 1,
            tmux_bin         => '/home/myuser/bin/tmux',
            'global-session' => {
                initialize => [qw( tmux new-session -d -s global-session )],
                on_connect => [ 'set status on', 'set-option prefix C-k', ],
            },
            'ansible-host' => {
                initialize => [qw( tmux new-session -d -s ansible )],
                on_connect => [ 'set status off', 'set-option set-titles-string "#T"' ],
            },
            'puppet-host' => {
                swm		  => 0,
                initialize => [qw( tmux new-session -d -s puppet )],
                on_connect => [ 'set status off' ],
            },
        },
    },
}
```

The value for the `terminal` key should be set to what your terminal uses to execute a custom command. Examples:

* `kitty`
* `xterm`
* `xfce4-terminal -e`
* `termit -e`
* `gnome-terminal -e`


To connect to a remote host, a number of conditions should be met for optimal use. First, ensure your local machine has keyed access to the remote host. Second, ensure that SSH multiplexing is allowed. Modern defaults usually allow 10 multiplexed clients. This means you can have 9 windows open, and one control session.  This can be increased by modifying `MaxSessions` in sshd_config on the remote host.

Each host requires a separate instance of tmuxc to be run. Using the above example, you'd run the following:

* `tmuxc -b` to connect to the localhost instance, under the default session of 'global-session', then daemonize tmuxc
* `tmuxc -h my.remote.server.com -b` to connect to the remote host, under the default session of 'global-session', then daemonize tmuxc.

Hosts and sessions do not need to be in the configuration file. You can simply run `tmuxc` as-is. The configuration file is just parsed by the internal `tmuxc -l` launcher mode to present a session selector for you.

When a terminal is closed with out exiting the program running in the tmux window (e.g. exiting a shell), that specific window is marked as 'ignored' for the life of the tmuxc process. That means that when you create a new window, the one you just closed and a new one do not open up. You can re-open all windows for a session by running `tmuxc -m` and selecting Open All Windows, and then picking a session if multiple exist.


# Hotkey integrations

Below is a sample i3 integration:

```
# Present the session launcher menu
bindsym $mod+equal exec --no-startup-id tmuxc -l
# Present a single-depth menu showing all sessions and the actions allowed for each
bindsym $mod+m exec --no-startup-id tmuxc -M
# Open a new terminal in the running session, or present a menu if multiple sessions are running
bindsym $mod+Return exec --no-startup-id tmuxc -n
```

# Global/host/session options

If the default option is acceptable, you do not need to define it again in a configuration file. However, if you want to change it for a specific host or even a specific session, you can do so. Define the configuration key and value at the appropriate level, and it will override that setting.

* `alive_count (default 2)`: Set the SSH `ServerAliveCountMax` option for control master connections.
* `alive_interval (default 3)`: Set the SSH `ServerAliveInterval` option for control master connections.
* `background (default 0)`: Set to 1 to automatically detach/background the tmuxc process after launch.
* `conn_timeout (default 3)`: Set the SSH `ConnectTimeout` option for control master connections.
* `detach (default 0)`: Set to 1 to attempt to detach all other clients connected to the TMUX session.
* `env_prefix (default TMUX_SESSION)`: Combine this prefix with `_NAME` and inject the tmux session name into the environment.
* `exitlast (default 0)`: Set to 1 to exit the control daemon after the last window in the tmux session exits.
* `input_prompt (default rofi -dmenu -p)`: Define the prompt for user input, notably when creating an ephemeral session.
* `log_facility (default "")`: Define the syslog log facility.
* `log_level (default 5)`: Define the logging level, values of 5, 6 or 7 are accepted.
* `on_connect (default[])`: When operating in single-window-mode, define an array of tmux commands to be sent to the cloned session to which you are attached. This option is only executed when `swm` is true.
* `persist (default 10s)`: Set the SSH `ControlPersist` option for control master connections.
* `prettyps (default 1)`: Control the process name on the command line, reducing it to `binaryname session@host`.
* `reconnect (default 1)`: Attempt to reconnect to the remote host and re-open windows if SSH drops. This is useful for laptops that are suspended frequently.
* `selector (default: rofi -dmenu -i)`: Define the menu command, used for picking a session / session action.
* `skipnw (default 0)`: Do not launch a new terminal when a new window is created in tmux. 
* `ssh_args(default [])`: Additional arguments to add to each SSH connection.
* `swm (default 0)`: Enable single-window-mode. This is the traditional approach to tmux, it simply opens a terminal with your full tmux session attached in it. Refer to `on_connect` for session tuning (set status on, for example, if it's off by default.)
* `temp (default $HOME/.tmuxc/)`: The location of the runtime temp directory. While this can be changed on a per-host and per-session basis, it should be avoided. `tmuxc` uses a shared directory to discover other running instances and to insert commands into other running sessions. Unless a shared directory is used, instances will be 'lost' to each other.
* `terminal (default xterm)`: The default terminal to use when opening up new windows.
* `tmux_bin (default tmux)`: The name of the tmux binary to use, can also include the full path like `/home/user/bin/tmux-3.0`.

Run `tmuxc -h <host> -s <session> -o` to see the merged configuration values for a given host and session. Some of the values shown (chost, command, control, etc) are generated at run-time and are not able to be configured by a user.
