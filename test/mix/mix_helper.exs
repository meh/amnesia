# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.start()
Mix.shell(Mix.Shell.Process)
Logger.remove_backend :console
