{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;

    settings = {
      theme = "dark";
      includeCoAuthoredBy = false;

      permissions = {
        #defaultMode = "acceptEdits";
        allow = [
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(make:*)"
          #"Edit"
          "Read"
        ];
        deny = [
          "Bash(rm -rf:*)"
          "Bash(curl:*)"
          "Bash(git commit:*)"
        ];
      };

      # Optional: hooks example
      # hooks = {
      #   PostToolUse = [{
      #     matcher = "Edit|Write";
      #     hooks = [{ type = "command"; command = "your-formatter $CLAUDE_TOOL_INPUT"; }];
      #   }];
      # };
    };

    # Personal slash commands — each .md file becomes a /command-name
    #commandsDir = ./commands;  # directory of .md files
    # or individual files:
    # commands = [ ./commands/my-cmd.md ];
  };
}
