function update_tmux --on-event fish_preexec
  if set -q TMUX_PANE
    export (tmux show-environment -t (env TMUX= tmux lsw -F "#{session_name}" | head -1)  | grep -v "^-" | xargs -L 1)
  end
end
