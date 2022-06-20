start /B iex.bat --werl --name 1@127.0.0.1 --cookie 1 -S mix run

start /B iex.bat --werl --name 2@127.0.0.1 --cookie 1 -S mix run

@REM manually connect the nodes together (normally you use libcluster)
@REM Node.connect(:'1@127.0.0.1')
