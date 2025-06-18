{...}: {
  system.stateVersion = "24.11";
  profiles = {
    #     eclss-node.enable = true;
    server.enable = true;
  };
  #   services.eclssd = {
  #     location = "bedroom";
  #     onlySensors = [ "SCD41" "BME680" "SEN55" ];
  #   };
}
