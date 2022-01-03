# libs
source lib/get_input.sh

# funcs
setup_ovpn(){
  # get servername for VPN
  prompt "Enter the OpenVPN domain name: "
  local vpn_server
  vpn_server=$(get_response '*' true)

  # setup OVPN config file
  docker run \
           -v "$(pwd)"/data/ovpn:/etc/openvpn \
           --log-driver=none \
           --rm \
           ghcr.io/ragingtiger/docker-openvpn:master \
             ovpn_genconfig -u udp://$vpn_server

  # initialize the EasyRSA PKI
  docker run \
           -v "$(pwd)"/data/ovpn:/etc/openvpn \
           --log-driver=none \
           --rm \
           -it \
           ghcr.io/ragingtiger/docker-openvpn:master \
             ovpn_initpki
}

setup_client_ovpn(){
  # get servername for VPN
  prompt "Enter the OpenVPN client name: "
  local client_name
  client_name=$(get_response '*' true)

  # setup OVPN client
  docker run \
           -v "$(pwd)"/data/ovpn:/etc/openvpn \
           --rm \
           -it \
           ghcr.io/ragingtiger/docker-openvpn:master \
             easyrsa \
               build-client-full \
                 "$client_name" \
                 nopass

  docker run \
           -v "$(pwd)"/data/ovpn:/etc/openvpn \
           --rm \
           ghcr.io/ragingtiger/docker-openvpn:master \
             ovpn_getclient \
               "$client_name" > "$client_name".ovpn
}

setup_ddns(){
  # create dirs
  sudo mkdir -p data/ddns

  # create config file
  sudo touch data/ddns/config.json

  # Owned by user ID of Docker container (1000)
  sudo chown -R 1000 data/ddns

  # all access (for creating json database file data/updates.json)
  sudo chmod 700 data/ddns
  
  # read access only
  sudo chmod 400 data/ddns/config.json
}

main(){
  # setup ovpn
  prompt "Would you like to setup OpenVPN? [Y/n]: "
  get_response setup_ovpn 'Y' false

  # setup client for ovpn
  prompt "Would you like to setup a client for OpenVPN? [Y/n]: "
  get_response setup_client_ovpn 'Y' false

  # setup ddns
  prompt "Would you like to setup DynamicDNS? [Y/n]: "
  get_response setup_ddns 'Y' false
}

# execute
main
