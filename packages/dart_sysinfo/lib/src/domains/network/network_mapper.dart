/// Maps FRB network DTOs to public domain models (TDD §4.5).
library;

import 'package:dart_sysinfo/src/bridge/api/network.dart';
import 'package:dart_sysinfo/src/domains/network/network_info.dart';
import 'package:dart_sysinfo/src/domains/network/network_throughput_sample.dart';

/// Maps a native [NetworkInfoDto] to the public [NetworkInfo] model.
NetworkInfo mapNetworkInfoDto(NetworkInfoDto dto) {
  return NetworkInfo(
    interfaces: dto.interfaces
        .map(mapNetworkInterfaceDto)
        .toList(growable: false),
  );
}

NetworkInterface mapNetworkInterfaceDto(NetworkInterfaceDto dto) {
  return NetworkInterface(
    name: dto.name,
    macAddress: dto.macAddress,
    ipNetworks: dto.ipNetworks
        .map(mapIpNetworkEntryDto)
        .toList(growable: false),
    mtu: dto.mtu.toInt(),
    operationalState: mapNetworkOperationalStateDto(dto.operationalState),
    cumulative: mapNetworkCumulativeStatsDto(dto.cumulative),
  );
}

IpNetworkEntry mapIpNetworkEntryDto(IpNetworkEntryDto dto) {
  return IpNetworkEntry(
    address: dto.address,
    prefixLength: dto.prefixLength,
  );
}

NetworkOperationalState mapNetworkOperationalStateDto(
  NetworkOperationalStateDto dto,
) {
  return switch (dto) {
    NetworkOperationalStateDto.up => NetworkOperationalState.up,
    NetworkOperationalStateDto.down => NetworkOperationalState.down,
    NetworkOperationalStateDto.testing => NetworkOperationalState.testing,
    NetworkOperationalStateDto.unknown => NetworkOperationalState.unknown,
    NetworkOperationalStateDto.dormant => NetworkOperationalState.dormant,
    NetworkOperationalStateDto.notPresent => NetworkOperationalState.notPresent,
    NetworkOperationalStateDto.lowerLayerDown =>
      NetworkOperationalState.lowerLayerDown,
  };
}

NetworkCumulativeStats mapNetworkCumulativeStatsDto(
  NetworkCumulativeStatsDto dto,
) {
  return NetworkCumulativeStats(
    totalReceivedBytes: dto.totalReceivedBytes.toInt(),
    totalTransmittedBytes: dto.totalTransmittedBytes.toInt(),
    totalPacketsReceived: dto.totalPacketsReceived.toInt(),
    totalPacketsTransmitted: dto.totalPacketsTransmitted.toInt(),
    totalErrorsOnReceived: dto.totalErrorsOnReceived.toInt(),
    totalErrorsOnTransmitted: dto.totalErrorsOnTransmitted.toInt(),
  );
}

/// Maps a native [NetworkThroughputSampleDto] to [NetworkThroughputSample].
NetworkThroughputSample mapNetworkThroughputSampleDto(
  NetworkThroughputSampleDto dto,
) {
  return NetworkThroughputSample(
    interfaces: dto.interfaces
        .map(mapNetworkThroughputInterfaceDto)
        .toList(growable: false),
  );
}

NetworkThroughputInterface mapNetworkThroughputInterfaceDto(
  NetworkThroughputInterfaceDto dto,
) {
  return NetworkThroughputInterface(
    name: dto.name,
    receivedBytes: dto.receivedBytes.toInt(),
    transmittedBytes: dto.transmittedBytes.toInt(),
    packetsReceived: dto.packetsReceived.toInt(),
    packetsTransmitted: dto.packetsTransmitted.toInt(),
    errorsOnReceived: dto.errorsOnReceived.toInt(),
    errorsOnTransmitted: dto.errorsOnTransmitted.toInt(),
  );
}
