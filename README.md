# tmuxc

tmuxc attaches to a local or remote tmux session and breaks out each window into a local terminal. Each window in a session is tracked by tmuxc, and when found, a shell script is created that is executed by a terminal of your choice. The shell script creates a new cloned session that's part of the base session you're monitoring, sets a few options, and focuses a specific window.  When that window in tmux is closed, the cloned session is killed, causing the script to finish executing and the terminal to close.

`tmuxc` is written in pure core PERL, so it should work as-is on most any modern system. It's been successfully tested on Ubuntu, Antergos, FreeBSD and OpenBSD.

Menu mode in `tmuxc` requires `rofi`. You can, of course, not use any of the menuing modes, but `rofi` is currently a hard requirement for the session picker and session manager modes. 

A few changes to tmux's configuration will need to be made. Because of the way tmuxc operates, new windows that are created in a session should not automatically get focus. This behavior is nominally controlled by the `-d` flag on new-window and breakp. A full list of changes to .tmux.conf are listed below.

```
# Create a new window, with out focus. This is only needed if you want to use tmux hotkeys to create a window. If you use tmuxc to create a new winodow, this keybind can be left alone.
bind-key c new-window -d

# Break the current pane out into a new window, without focus. There is no tmuxc shortcut for this action.
bind b breakp -d

# This ensures that when you exit a shell / close a window, the terminal viewing that window does not refocus to another window
set-option -g detach-on-destroy on

# Ensure that when a program exits (e.g. your shell), the window is destroyed which results in the terminal correctly closing
set-option -g remain-on-exit off
```

Example ~/.tmuxc.conf for a local tmux instance
```
{
  temp      => "$ENV{'HOME'}/.tmuxc/",
  terminal  => [ qw(xterm) ],
  sesion   => 'global-session',
  hosts     =>  {
    localhost => {
      'global-session' => {
        initialize  => [ qw(tmux new-session -d -s global-session) ],
      },
    }, 
  },
}
```

The value for the `terminal` key should be set to what your terminal uses to execute a custom command. Examples:

* `xfce4-terminal -e`
* `termit -e`
* `gnome-terminal -e`

To connect to a remote host, a number of conditions should be met for optimal use. First, ensure your local machine has keyed access to the remote host. Second, ensure that SSH multiplexing is allowed. Modern defaults usually allow 10 multiplexed clients. This means you can have 9 windows open, and one control session.  This can be increased by modifying `MaxSessions` in sshd_config on the remote host.

Example .tmuxc.conf for a local and a remote instance:

```
{
  temp      => "$ENV{'HOME'}/.tmuxc/",
  terminal  => [ qw(gnome-terminal -e) ],
  sesion   => 'global-session',
  hosts     =>  {
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

Each host requires a separate instance of tmuxc to be run. Using the above example, you'd run the following:

* `tmuxc -b` to connect to the localhost instance, under the default session of 'global-session', then daemonize tmuxc
* `tmuxc -h my.remote.server.com -b` to connect to the remote host, under the default session of 'global-session', then daemonize tmuxc.

Hosts and sessions do not need to be in the configuration file. You can simply run `tmuxc` as-is. The configuration file is just parsed by the internal `tmuxc -l` rofi mode to present a session launcher for you.

When a terminal is closed with out exiting the program running in the tmux window (e.g. exiting a shell), that specific window is marked as 'ignored' for the life of the tmuxc process. That means that when you create a new window, the one you just closed and a new one do not open up. You can re-open all windows for a session by running `tmuxc -m` and selecting Open All Windows, and then picking a session if multiple exist.

Below is a sample i3 integration:

```
bindsym $mod+equal exec --no-startup-id tmuxc -l
bindsym $mod+m exec --no-startup-id tmuxc -m
bindsym $mod+Return exec --no-startup-id tmuxc -n
```

In order, there's a tmuxc session launcher, a tmuxc session manager (open/close windows, kill tmuxc), and a key to create a new window. If you have only one tmuxc instance running, `$mod+Return` creates a window in that session. If you have multiple instances, you're prompted to pick which one to use. The prompt can be bypassed by specifying a host and a session name to help narrow down which to use.

A full configuration, with a mix of options:
```
{
  temp      => "$ENV{'HOME'}/.tmuxc/",
  terminal  => [ qw(xterm) ],
  session   => 'global-session',
  hosts     =>  {
    'workstation' => {
      'global-session' => {
        blacklist   => [ 'mocp', 'htop', 'ignore' ],
        initialize  => [ qw(/usr/local/bin/tmuxp load -2 -d global-session.yml) ],
      },
    },
    localhost => {
      'global-session' => {
        initialize  => [ qw(tmux new-session -d -s global-session) ],
      },
    },
    'hypervisor' => {
      skipnw => 1,
      killrc => 1,
      'global-session' => {
        initialize  => [ qw(tmux new-session -d -s global-session) ],
      },
      'vm-monitor' => {
        initialize => { qw(/usr/local/bin/tmuxp load -2 -d monitor.yml'
      },
    },
    'irc.vm' => {
      'weechat' => {
        skipnw => 1,
        detach => 1,
        blacklist => [ 'top' ],
        initialize  => [ qw(/usr/local/bin/tmuxp-3.6 load -2 -d ~/weechat.yml) ],
      },
    }, 
  },
}
```

The following configuration directives can be set at the session, host or global level.

* `detach` - Attempt to detach all other clients connected to this session
* `killrc` - If running, kill an instance of tmuxc running for this session on the remote host you are connected to
* `pauserc` - If running, set the remote instance of tmuxc to pause mode, where it ignores all tmux events and commands
* `reconnect` - Attempt to reconnect to the remote host and re-open windows if SSH drops. This is useful for laptops that are suspended frequently.
* `closeas` - After opening all windows found on startup, tmuxc will exit. So-called one-shot mode.
* `background` - Automatically background tmuxc on startup, reparenting to pid 1.
* `blacklist` - An array of window titles that should be skipped when windows are created.
* `skipnw` - Do not launch a new terminal when a new window is created in tmux. 
* `exitlast` - Exit the control daemon after the last tmux window in the session exits.
