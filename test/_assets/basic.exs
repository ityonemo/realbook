# basic realbook that creates a directory in the temp directory.

def path, do: get(:dirname)

verify do
  (run! "test -d #{path()}")
end

play do
  log  "creating #{path()}"
  run! "mkdir -p #{path()}"
end
