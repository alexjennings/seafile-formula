$set_hostname = <<SCRIPT
if grep --quiet $1 /etc/hosts
then
  echo "Hostname correct"
else
  echo "127.0.0.1   localhost   localhost.localdomain
$1    $2"> /etc/hosts
fi
SCRIPT

box = {
  :name => :seafile,
  :ip => '192.168.9.35',
  :memory => 1024,
  }

Vagrant.configure("2") do |config|
  config.vm.box = "puppetlabs/centos-7.0-64-nocm"
  config.vm.box_url = "puppetlabs/centos-7.0-64-nocm"
  config.vm.network :private_network, ip: box[:ip]

  config.vm.synced_folder "salt", "/srv/salt/", create: true
  config.vm.synced_folder "pillar", "/srv/pillar/", create: true



  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", box[:memory]]
  end

  config.vm.define box[:name] do |config|
    config.vm.hostname = "%s" % box[:name].to_s
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.auto_detect = false
    config.cache.enable :yum
    config.cache.scope = :box
  end

    config.vm.provision "shell" do |s|
      s.inline = $set_hostname
      s.args   = [box[:ip], box[:name].to_s]
    end


  config.vm.provision :salt do |salt|
    salt.run_highstate = false
    salt.no_minion = false
    salt.colorize = true
    salt.minion_config = "minion"
    salt.always_install = true
    salt.verbose = true

  end

end
