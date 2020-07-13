verify false

play do
  set foo: "bar"
  send((get :test_pid), :dependency)
end
