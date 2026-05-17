/**
 * 6H: Settings Screen
 * User preferences and configuration
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Switch,
  Alert,
  Picker
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { StorageService, UserPreferences } from '@services/storage';
import { useAppState } from '@hooks/useAppState';

function SettingsScreen(): React.JSX.Element {
  const { setServerUrl, setTheme } = useAppState();
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [cacheSize, setCacheSize] = useState(0);

  useEffect(() => {
    loadSettings();
  }, []);

  async function loadSettings() {
    try {
      const prefs = await StorageService.getPreferences();
      setPreferences(prefs);

      const size = await StorageService.getCacheSize();
      setCacheSize(size);
    } catch (error) {
      console.error('[Settings] Error loading preferences:', error);
    }
  }

  async function handleServerUrlChange(url: string) {
    if (preferences) {
      const updated = { ...preferences, serverUrl: url };
      setPreferences(updated);
      await StorageService.savePreferences({ serverUrl: url });
      await setServerUrl(url);
    }
  }

  async function handleThemeChange(theme: 'light' | 'dark' | 'auto') {
    if (preferences) {
      const updated = { ...preferences, theme };
      setPreferences(updated);
      await StorageService.savePreferences({ theme });
      await setTheme(theme);
    }
  }

  async function handleClearCache() {
    Alert.alert('Clear Cache', 'This will remove all cached proofs and data.', [
      { text: 'Cancel', onPress: () => {} },
      {
        text: 'Clear',
        onPress: async () => {
          try {
            await StorageService.clearCache();
            setCacheSize(0);
            Alert.alert('Success', 'Cache cleared');
          } catch (error) {
            Alert.alert('Error', String(error));
          }
        }
      }
    ]);
  }

  async function handleNotificationsToggle(enabled: boolean) {
    if (preferences) {
      const updated = { ...preferences, notificationsEnabled: enabled };
      setPreferences(updated);
      await StorageService.savePreferences({ notificationsEnabled: enabled });
    }
  }

  if (!preferences) {
    return <Text>Loading...</Text>;
  }

  const cacheSizeMB = (cacheSize / 1024 / 1024).toFixed(2);

  return (
    <ScrollView style={styles.container}>
      {/* Server Configuration */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Server Configuration</Text>

        <View style={styles.settingItem}>
          <Text style={styles.settingLabel}>WebSocket URL</Text>
          <TextInput
            style={styles.input}
            value={preferences.serverUrl}
            onChangeText={handleServerUrlChange}
            placeholder="ws://localhost:8765"
            placeholderTextColor="#C7C7CC"
          />
          <Text style={styles.hint}>e.g., ws://localhost:8765 or wss://your-server.com</Text>
        </View>
      </View>

      {/* Display Settings */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Display</Text>

        <View style={styles.settingItem}>
          <View style={styles.settingRow}>
            <Text style={styles.settingLabel}>Theme</Text>
          </View>
          <Picker
            selectedValue={preferences.theme}
            onValueChange={handleThemeChange}
            style={styles.picker}
          >
            <Picker.Item label="Light" value="light" />
            <Picker.Item label="Dark" value="dark" />
            <Picker.Item label="Auto (System)" value="auto" />
          </Picker>
        </View>

        <View style={styles.settingItem}>
          <View style={styles.settingRow}>
            <Text style={styles.settingLabel}>Auto-refresh Interval</Text>
            <Text style={styles.settingValue}>{preferences.autoRefreshInterval}s</Text>
          </View>
          <Picker
            selectedValue={preferences.autoRefreshInterval}
            onValueChange={(value) => {
              StorageService.savePreferences({ autoRefreshInterval: value as number });
              setPreferences({ ...preferences, autoRefreshInterval: value as number });
            }}
            style={styles.picker}
          >
            <Picker.Item label="5 seconds" value={5} />
            <Picker.Item label="10 seconds" value={10} />
            <Picker.Item label="30 seconds" value={30} />
            <Picker.Item label="Off" value={0} />
          </Picker>
        </View>
      </View>

      {/* Notifications */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Notifications</Text>

        <View style={styles.settingItem}>
          <View style={styles.settingRow}>
            <Text style={styles.settingLabel}>Enable Notifications</Text>
            <Switch
              value={preferences.notificationsEnabled}
              onValueChange={handleNotificationsToggle}
            />
          </View>
          <Text style={styles.hint}>Receive push notifications for new proofs</Text>
        </View>
      </View>

      {/* Storage & Cache */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Storage & Cache</Text>

        <View style={styles.storageInfo}>
          <View style={styles.storageItem}>
            <Icon name="storage" size={24} color="#007AFF" />
            <View style={styles.storageText}>
              <Text style={styles.storageLabel}>Cache Size</Text>
              <Text style={styles.storageValue}>{cacheSizeMB} MB</Text>
            </View>
          </View>

          <TouchableOpacity style={styles.clearButton} onPress={handleClearCache}>
            <Icon name="delete" size={18} color="white" />
            <Text style={styles.clearButtonText}>Clear Cache</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* About */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>

        <View style={styles.aboutItem}>
          <Text style={styles.aboutLabel}>App Name</Text>
          <Text style={styles.aboutValue}>Omega OS Mobile</Text>
        </View>

        <View style={styles.aboutItem}>
          <Text style={styles.aboutLabel}>Version</Text>
          <Text style={styles.aboutValue}>0.1.0</Text>
        </View>

        <View style={styles.aboutItem}>
          <Text style={styles.aboutLabel}>Phase</Text>
          <Text style={styles.aboutValue}>Phase 6</Text>
        </View>

        <View style={styles.aboutItem}>
          <Text style={styles.aboutLabel}>Build Date</Text>
          <Text style={styles.aboutValue}>{new Date().toLocaleDateString()}</Text>
        </View>

        <View style={styles.aboutDescription}>
          <Text style={styles.aboutDescriptionText}>
            Real-time dashboard for Omega OS with WebSocket streaming, lane monitoring, and remote task submission.
          </Text>
        </View>
      </View>

      {/* Debug */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Debug</Text>

        <TouchableOpacity
          style={styles.debugButton}
          onPress={() => {
            Alert.alert(
              'Preferences',
              JSON.stringify(preferences, null, 2),
              [{ text: 'OK', onPress: () => {} }]
            );
          }}
        >
          <Icon name="bug-report" size={18} color="#666" />
          <Text style={styles.debugButtonText}>View Preferences JSON</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.spacer} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7'
  },
  section: {
    backgroundColor: 'white',
    borderTopWidth: 1,
    borderTopColor: '#E5E5EA',
    paddingVertical: 8
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    paddingHorizontal: 16,
    paddingVertical: 12,
    color: '#333'
  },
  settingItem: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F2F2F7'
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  settingLabel: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333'
  },
  settingValue: {
    fontSize: 12,
    color: '#8E8E93'
  },
  input: {
    backgroundColor: '#F2F2F7',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    color: '#333',
    marginTop: 8,
    marginBottom: 4
  },
  hint: {
    fontSize: 11,
    color: '#8E8E93',
    marginTop: 4
  },
  picker: {
    height: 40,
    backgroundColor: '#F2F2F7',
    borderRadius: 8,
    marginTop: 8
  },
  storageInfo: {
    paddingHorizontal: 16,
    paddingVertical: 12
  },
  storageItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12
  },
  storageText: {
    marginLeft: 12,
    flex: 1
  },
  storageLabel: {
    fontSize: 12,
    color: '#8E8E93'
  },
  storageValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333'
  },
  clearButton: {
    backgroundColor: '#FF3B30',
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center'
  },
  clearButtonText: {
    color: 'white',
    fontWeight: '600',
    marginLeft: 8
  },
  aboutItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F2F2F7'
  },
  aboutLabel: {
    fontSize: 13,
    color: '#8E8E93'
  },
  aboutValue: {
    fontSize: 13,
    fontWeight: '500',
    color: '#333'
  },
  aboutDescription: {
    paddingHorizontal: 16,
    paddingVertical: 12
  },
  aboutDescriptionText: {
    fontSize: 12,
    color: '#666',
    lineHeight: 18
  },
  debugButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F2F2F7'
  },
  debugButtonText: {
    fontSize: 14,
    color: '#666',
    marginLeft: 12
  },
  spacer: {
    height: 40
  }
});

export default SettingsScreen;
