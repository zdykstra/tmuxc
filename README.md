# tmuxc

tmuxc attaches to a local or remote tmux session and breaks out each window into a local terminal. Each window in a session is tracked by tmuxc, and when found, a shell script is created that is executed by a terminal of your choice. The shell script creates a new cloned session that's part of the base session you're monitoring, sets a few options, and focuses a specific window.  When that window in tmux is closed, the cloned session is killed, causing the script to finish executing and the terminal to close.

You'll need to modify .tmux.conf and bind a key to the command `new-window -d`. This will cause a new window to be created without changing which window the last in-focus terminal displays.

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

* `tmuxc -b` to connect to the localhost instance, under the default session of 'global-session'
* `tmuxc -h my.remote.server.com` to connect to the remote host, under the default session of 'global-session'

Hosts and sessions do not need to be in the configuration file. You can simply run `tmuxc` as-is. The configuration file is just parsed by the internal `tmuxc -l` rofi mode to present a session launcher for you.


When a terminal is closed with out exiting the program running in the tmux window (e.g. exiting a shell), that specific window is marked as 'ignored' for the life of the tmuxc process. That means that when you create a new window, the one you just closed and a new one do not open up. You can re-open all windows for a session by running `tmuxc -m` and selecting Open All Windows, and then picking a session if multiple exist.

Below is a sample i3 integration:

```
bindsym $mod+equal exec --no-startup-id tmuxc -l
bindsym $mod+m exec --no-startup-id tmuxc -m
bindsym $mod+Return exec --no-startup-id tmuxc -n
```

In order, there's a tmuxc session launcher, a tmuxc session manager (open/close windows, kill tmuxc), and a key to create a new window. If you have only one tmuxc instance running, `$mod+Return` creates a window in that session. If you have multiple instances, you're prompted to pick which one to use. The prompt can be bypassed by specifying a host and a session name to help narrow down which to use.
