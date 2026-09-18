import 'dart:async';

import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:example/format_reading.dart';
import 'package:flutter/material.dart';

/// Demonstrates P1 OS, CPU, and memory domains plus a CPU load stream.
class P1DemoPage extends StatefulWidget {
  const P1DemoPage({
    required this.smokePingResult,
    this.autoStartStream = false,
    super.key,
  });

  final int smokePingResult;

  /// When true (via `--dart-define=QA_AUTO_START=true`), starts the CPU load
  /// stream on launch for hot-restart manual QA log verification.
  final bool autoStartStream;

  @override
  State<P1DemoPage> createState() => _P1DemoPageState();
}

class _P1DemoPageState extends State<P1DemoPage> {
  OsInfo? _osInfo;
  MemoryInfo? _memoryInfo;
  CpuInfo? _cpuInfo;
  DisksInfo? _disksInfo;
  NetworkInfo? _networkInfo;
  String? _errorMessage;
  bool _loadingSnapshots = false;

  StreamSubscription<CpuLoadSample>? _loadSubscription;
  int _tickCount = 0;
  CpuLoadSample? _lastSample;
  DateTime? _lastTickAt;
  bool _streamActive = false;

  StreamSubscription<NetworkThroughputSample>? _throughputSubscription;
  int _throughputTickCount = 0;
  NetworkThroughputSample? _lastThroughputSample;
  DateTime? _lastThroughputTickAt;
  bool _throughputStreamActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStartStream) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_startLoadStream());
      });
    }
  }

  @override
  void dispose() {
    unawaited(_loadSubscription?.cancel());
    unawaited(_throughputSubscription?.cancel());
    super.dispose();
  }

  Future<void> _refreshSnapshots() async {
    setState(() {
      _loadingSnapshots = true;
      _errorMessage = null;
    });

    try {
      final sysInfo = SysInfo.instance;
      final results = await Future.wait([
        sysInfo.os.snapshot(forceRefresh: true),
        sysInfo.memory.snapshot(forceRefresh: true),
        sysInfo.cpu.snapshot(forceRefresh: true),
        sysInfo.disks.snapshot(forceRefresh: true),
        sysInfo.network.snapshot(forceRefresh: true),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _osInfo = results[0] as OsInfo;
        _memoryInfo = results[1] as MemoryInfo;
        _cpuInfo = results[2] as CpuInfo;
        _disksInfo = results[3] as DisksInfo;
        _networkInfo = results[4] as NetworkInfo;
        _loadingSnapshots = false;
      });
    } on SysInfoException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _loadingSnapshots = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _loadingSnapshots = false;
      });
    }
  }

  Future<void> _startLoadStream() async {
    await _loadSubscription?.cancel();
    setState(() {
      _errorMessage = null;
      _tickCount = 0;
      _lastSample = null;
      _lastTickAt = null;
      _streamActive = true;
    });

    try {
      _loadSubscription = SysInfo.instance.cpu.load().listen(
        (sample) {
          if (!mounted) {
            return;
          }
          setState(() {
            _tickCount++;
            _lastSample = sample;
            _lastTickAt = DateTime.now();
          });
          debugPrint('[CPU_LOAD] tick $_tickCount');
        },
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _streamActive = false;
            _errorMessage = error is SysInfoException
                ? error.message
                : error.toString();
          });
        },
      );
    } on SysInfoException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _streamActive = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _stopLoadStream() async {
    await _loadSubscription?.cancel();
    _loadSubscription = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _streamActive = false;
    });
  }

  Future<void> _startThroughputStream() async {
    await _throughputSubscription?.cancel();
    setState(() {
      _errorMessage = null;
      _throughputTickCount = 0;
      _lastThroughputSample = null;
      _lastThroughputTickAt = null;
      _throughputStreamActive = true;
    });

    try {
      _throughputSubscription = SysInfo.instance.network.throughput().listen(
        (sample) {
          if (!mounted) {
            return;
          }
          setState(() {
            _throughputTickCount++;
            _lastThroughputSample = sample;
            _lastThroughputTickAt = DateTime.now();
          });
          debugPrint('[NETWORK_THROUGHPUT] tick $_throughputTickCount');
        },
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _throughputStreamActive = false;
            _errorMessage = error is SysInfoException
                ? error.message
                : error.toString();
          });
        },
      );
    } on SysInfoException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _throughputStreamActive = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _stopThroughputStream() async {
    await _throughputSubscription?.cancel();
    _throughputSubscription = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _throughputStreamActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dart_sysinfo P1 demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_errorMessage != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_errorMessage!),
              ),
            ),
          _SnapshotSection(
            title: 'OS',
            onRefresh: _refreshSnapshots,
            loading: _loadingSnapshots,
            lines: _osInfo == null
                ? const ['Tap Refresh to load OS snapshot.']
                : [
                    'name: ${formatReading(_osInfo!.name)}',
                    'kernel: ${formatReading(_osInfo!.kernelVersion)}',
                    'uptime: ${_osInfo!.uptimeSeconds}s',
                    'load avg: ${formatReading(_osInfo!.loadAverage)}',
                  ],
          ),
          _SnapshotSection(
            title: 'Memory',
            onRefresh: _refreshSnapshots,
            loading: _loadingSnapshots,
            lines: _memoryInfo == null
                ? const ['Tap Refresh to load memory snapshot.']
                : _memoryLines(),
          ),
          _SnapshotSection(
            title: 'CPU',
            onRefresh: _refreshSnapshots,
            loading: _loadingSnapshots,
            lines: _cpuInfo == null
                ? const ['Tap Refresh to load CPU snapshot.']
                : _cpuLines(),
          ),
          _SnapshotSection(
            title: 'Disks',
            onRefresh: _refreshSnapshots,
            loading: _loadingSnapshots,
            lines: _disksInfo == null
                ? const ['Tap Refresh to load disks snapshot.']
                : _disksLines(),
          ),
          _SnapshotSection(
            title: 'Network',
            onRefresh: _refreshSnapshots,
            loading: _loadingSnapshots,
            lines: _networkInfo == null
                ? const ['Tap Refresh to load network snapshot.']
                : _networkLines(),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CPU load stream',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${_streamActive ? 'running' : 'stopped'}'),
                  Text('Ticks: $_tickCount'),
                  Text(_lastSampleText()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _streamActive ? null : _startLoadStream,
                        child: const Text('Start'),
                      ),
                      OutlinedButton(
                        onPressed: _streamActive ? _stopLoadStream : null,
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network throughput stream',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: '
                    '${_throughputStreamActive ? 'running' : 'stopped'}',
                  ),
                  Text('Ticks: $_throughputTickCount'),
                  Text(_lastThroughputSampleText()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _throughputStreamActive
                            ? null
                            : _startThroughputStream,
                        child: const Text('Start'),
                      ),
                      OutlinedButton(
                        onPressed: _throughputStreamActive
                            ? _stopThroughputStream
                            : null,
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ExpansionTile(
            title: const Text('Debug: FFI smoke ping'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(_smokePingText()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _memoryLines() {
    final memory = _memoryInfo!;
    return [
      'total: ${formatBytes(memory.totalMemoryBytes)}',
      'used: ${formatBytes(memory.usedMemoryBytes)}',
      'available: ${formatBytes(memory.availableMemoryBytes)}',
    ];
  }

  List<String> _cpuLines() {
    final cpu = _cpuInfo!;
    return [
      'architecture: ${cpu.architecture}',
      'physical cores: ${formatReading(cpu.physicalCoreCount)}',
      'global usage: ${formatReading(cpu.globalUsagePercent)}',
    ];
  }

  List<String> _disksLines() {
    final disks = _disksInfo!;
    if (disks.volumes.isEmpty) {
      return const ['volumes: 0 (empty list is valid on sandboxes)'];
    }
    final first = disks.volumes.first;
    return [
      'volumes: ${disks.volumes.length}',
      'first mount: ${first.mountPoint}',
    ];
  }

  List<String> _networkLines() {
    final network = _networkInfo!;
    if (network.interfaces.isEmpty) {
      return const ['interfaces: 0 (empty list is valid)'];
    }
    final first = network.interfaces.first;
    return [
      'interfaces: ${network.interfaces.length}',
      'first name: ${first.name}',
    ];
  }

  String _lastSampleText() {
    if (_lastSample == null) {
      return 'Last sample: none';
    }
    final usage = _lastSample!.globalUsagePercent.toStringAsFixed(1);
    return 'Last: $usage% at ${_formatTime(_lastTickAt)}';
  }

  String _lastThroughputSampleText() {
    if (_lastThroughputSample == null) {
      return 'Last sample: none';
    }
    final interfaces = _lastThroughputSample!.interfaces;
    if (interfaces.isEmpty) {
      return 'Last: 0 interfaces at ${_formatTime(_lastThroughputTickAt)}';
    }
    final first = interfaces.first;
    return 'Last: ${first.name} rx=${first.receivedBytes} tx='
        '${first.transmittedBytes} at ${_formatTime(_lastThroughputTickAt)}';
  }

  String _smokePingText() {
    final status = widget.smokePingResult == 42 ? 'SUCCESS' : 'UNEXPECTED';
    return 'frb_platform_smoke_ping() = ${widget.smokePingResult} ($status)';
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return 'n/a';
    }
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }
}

class _SnapshotSection extends StatelessWidget {
  const _SnapshotSection({
    required this.title,
    required this.onRefresh,
    required this.loading,
    required this.lines,
  });

  final String title;
  final VoidCallback onRefresh;
  final bool loading;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: loading ? null : onRefresh,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final line in lines) Text(line),
          ],
        ),
      ),
    );
  }
}
