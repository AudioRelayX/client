import 'package:audio_relay_x_client/data/audio/capture.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientMainPage extends StatefulWidget {
  const ClientMainPage({super.key});

  @override
  State<ClientMainPage> createState() => _ClientMainPageState();
}

class _ClientMainPageState extends State<ClientMainPage> {
  SharedPreferences? prefs;

  static const String _messageDismissedKey = 'server_message_dismissed';

  static final Uri serverReleaseUri = Uri.parse(
    'https://github.com/AudioRelayXX/server/releases',
  );

  final TextEditingController _ipController = TextEditingController();

  bool _showServerMessage = true;
  bool _isScanning = false;

  List<String> connections = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();

    final dismissed = prefs!.getBool(_messageDismissedKey) ?? false;

    if (!mounted) return;

    setState(() {
      _showServerMessage = !dismissed;
    });
  }

  Future<void> _dismissServerMessage() async {
    await prefs?.setBool(_messageDismissedKey, true);

    if (!mounted) return;

    setState(() {
      _showServerMessage = false;
    });
  }

  Future<void> _openServerReleases() async {
    if (!await launchUrl(
      serverReleaseUri,
      mode: LaunchMode.externalApplication,
    )) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the server download page.'),
        ),
      );
    }
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
    });

    // TODO: Implement network/device discovery here.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isScanning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device scan completed.'),
      ),
    );
  }

  void _connectToIp() {
    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an IP address first.'),
        ),
      );
      return;
    }

    // TODO: Connect to server using the IP address.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to $ip...'),
      ),
    );
  }

  void _selectMicrophone() {
    // TODO: Open microphone/source selection.
  }

  void _selectApps() {
    AudioClient client =
        AudioClient(destinationAddress: _ipController.text.trim());
    client.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text(
              'AudioRelayX',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                if (_showServerMessage) ...[
                  _buildWelcomeCard(theme),
                  const SizedBox(height: 24),
                ],
                _buildConnectionSection(theme),
                const SizedBox(height: 32),
                _buildConnectionsSection(theme),
                const SizedBox(height: 40),
                _buildSourcesSection(theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get started',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'To stream audio to another device, install the '
                    'AudioRelayX server on the receiving device.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _openServerReleases,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Download server'),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: _dismissServerMessage,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect to a device',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Find a server on your network or connect manually.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isScanning ? null : _scanForDevices,
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.radar_rounded),
                label: Text(
                  _isScanning ? 'Scanning...' : 'Scan for devices',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ipController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _connectToIp(),
                decoration: InputDecoration(
                  labelText: 'IP address',
                  hintText: '192.168.1.100',
                  prefixIcon: const Icon(Icons.lan_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Connect',
                    onPressed: _connectToIp,
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Connections',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (connections.isNotEmpty)
              Text(
                '${connections.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (connections.isEmpty)
          _buildEmptyConnections(theme)
        else
          ...connections.map(
            (connection) => _buildConnectionTile(
              theme,
              connection,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyConnections(ThemeData theme) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 28,
        ),
        child: Column(
          children: [
            Icon(
              Icons.devices_other_rounded,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No connections',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan your network to find available servers.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTile(
    ThemeData theme,
    String connection,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.computer_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          connection,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text('Available'),
        trailing: FilledButton(
          onPressed: () {
            // TODO: Connect.
          },
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Widget _buildSourcesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sources',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose what audio you want to stream.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildSourceButton(
                theme: theme,
                icon: Icons.mic_rounded,
                title: 'Microphone',
                subtitle: 'Stream microphone input',
                onPressed: _selectMicrophone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSourceButton(
                theme: theme,
                icon: Icons.apps_rounded,
                title: 'Apps',
                subtitle: 'Stream application audio',
                onPressed: _selectApps,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceButton({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Select',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
