# tmuxc

tmuxc attaches to a local or remote tmux session and breaks out each window into a local terminal. Each window in a session is tracked by tmuxc, and when found, a shell script is created that is executed by a terminal of your choice. The shell script creates a new cloned session that's part of the base session you're monitoring, sets a few options, and focuses a specific window.  When that window in tmux is closed, the cloned session is killed, causing the script to finish executing and the terminal to close.

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
