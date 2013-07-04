test_name "puppet module install (already installed with local changes)"

module_author = "pmtacceptance"
module_name   = "nginx"
module_dependencies   = []

teardown do
  on master, "rm -rf #{master['distmoduledir']}/*"
  agents.each do |agent|
    on agent, "rm -rf #{agent['distmoduledir']}/*"
  end
  on master, "rm -rf #{master['sitemoduledir']}/#{module_name}"
  module_dependencies.each do |dependency|
    on master, "rm -rf #{master['sitemoduledir']}/#{dependency}"
  end
end

step 'Setup'

stub_forge_on(master)

apply_manifest_on master, <<-PP
file {
  [
    '#{master['distmoduledir']}/#{module_name}',
  ]: ensure => directory;
  '#{master['distmoduledir']}/#{module_name}/metadata.json':
    content => '{
      "name": "#{module_author}/#{module_name}",
      "version": "0.0.1",
      "source": "",
      "author": "#{module_author}",
      "license": "MIT",
      "checksums": {
        "README": "2a3adc3b053ef1004df0a02cefbae31f"
      },
      "dependencies": []
    }';
  '#{master['distmoduledir']}/#{module_name}/README':
    content => '#{module_name} module';
}
PP


step "Try to install a module that is already installed"
on master, puppet("module install #{module_author}-#{module_name}"), :acceptable_exit_codes => [1] do
  assert_output <<-OUTPUT
    STDOUT> \e[mNotice: Preparing to install into #{master['distmoduledir']} ...\e[0m
    STDERR> \e[1;31mError: Could not install module '#{module_author}-#{module_name}' (latest)
    STDERR>   Module '#{module_author}-#{module_name}' (v0.0.1) is already installed
    STDERR>     Installed module has had changes made locally
    STDERR>     Use `puppet module upgrade` to install a different version
    STDERR>     Use `puppet module install --force` to re-install only this module\e[0m
  OUTPUT
end
on master, "[ -d #{master['distmoduledir']}/#{module_name} ]"

step "Try to install a specific version of a module that is already installed"
on master, puppet("module install #{module_author}-#{module_name} --version 1.x"), :acceptable_exit_codes => [1] do
  assert_output <<-OUTPUT
    STDOUT> \e[mNotice: Preparing to install into #{master['distmoduledir']} ...\e[0m
    STDERR> \e[1;31mError: Could not install module '#{module_author}-#{module_name}' (v1.x)
    STDERR>   Module '#{module_author}-#{module_name}' (v0.0.1) is already installed
    STDERR>     Installed module has had changes made locally
    STDERR>     Use `puppet module upgrade` to install a different version
    STDERR>     Use `puppet module install --force` to re-install only this module\e[0m
  OUTPUT
end
on master, "[ -d #{master['distmoduledir']}/#{module_name} ]"

step "Install a module that is already installed (with --force)"
on master, puppet("module install #{module_author}-#{module_name} --force") do
  assert_output <<-OUTPUT
    \e[mNotice: Preparing to install into #{master['distmoduledir']} ...\e[0m
    \e[mNotice: Downloading from https://forge.puppetlabs.com ...\e[0m
    \e[mNotice: Installing -- do not interrupt ...\e[0m
    #{master['distmoduledir']}
    └── #{module_author}-#{module_name} (\e[0;36mv0.0.1\e[0m)
  OUTPUT
end
on master, "[ -d #{master['distmoduledir']}/#{module_name} ]"
#validate checksum
