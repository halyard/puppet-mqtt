# @summary Configure MQTT instance
#
# @param datadir handles storage of MQTT data
# @param ip sets the IP of the mqtt container
class mqtt (
  String $datadir,
  String $ip = '172.17.0.4',
) {
  firewall { '100 dnat for mqtt':
    chain  => 'DOCKER_EXPOSE',
    jump   => 'DNAT',
    proto  => 'tcp',
    dport  => 1883,
    todest => "${ip}:1883",
    table  => 'nat',
  }

  file { [
      $datadir,
      "${datadir}/mqtt_config",
      "${datadir}/mqtt_data",
    ]:
      ensure => directory,
  }

  docker::container { 'mqtt':
    image   => 'eclipse-mosquitto:2',
    args    => [
      "--ip ${ip}",
      "-v ${datadir}/mqtt_data:/mosquitto/data",
      "-v ${datadir}/mqtt_config:/mosquitto/config",
    ],
    cmd     => 'mosquitto -c /mosquitto-no-auth.conf',
    require => [File["${datadir}/mqtt_config"], File["${datadir}/mqtt_data"]],
  }
}
