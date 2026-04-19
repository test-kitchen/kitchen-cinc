describe command("cinc-client -v") do
  its("stdout") { should match(/Cinc Client/) }
end
