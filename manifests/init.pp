# @summary Configure MQTT instance
#
# @param datadir handles storage of MQTT data
# @param ip sets the IP of the mqtt container
# @param metrics enables the mqtt-exporter sidecar container
# @param metrics_ip sets the IP of the metrics container
class mqtt (
  String $datadir,
  String $ip = '172.17.0.4',
  Boolean $metrics = true,
  String $metrics_ip = '172.17.0.5',
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

  if $metrics {
    firewall { '100 dnat for mqtt-exporter':
      chain  => 'DOCKER_EXPOSE',
      jump   => 'DNAT',
      proto  => 'tcp',
      dport  => 9000,
      todest => "${metrics_ip}:9000",
      table  => 'nat',
    }

    docker::container { 'mqtt-exporter':
      image => 'kpetrem/mqtt-exporter:latest',
      args  => [
        "--ip ${metrics_ip}",
        "-e MQTT_ADDRESS=${ip}",
      ],
    }
  }
}
