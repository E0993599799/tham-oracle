/**
 * 6A: Core Mobile App
 * Main React Native app entry point with navigation
 */

import React, { useEffect, useRef } from 'react';
import { View, StatusBar, ActivityIndicator, Text } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useAppState } from '@hooks/useAppState';
import { getWebSocketClient, ConnectionState } from '@services/websocket';
import { notificationService } from '@services/notifications';
import { StorageService } from '@services/storage';

// Screens
import DashboardScreen from './screens/DashboardScreen';
import LanesScreen from './screens/LanesScreen';
import SubmitTaskScreen from './screens/SubmitTaskScreen';
import SettingsScreen from './screens/SettingsScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

function DashboardTabs() {
  const { state } = useAppState();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: true,
        tabBarIcon: ({ focused, color, size }) => {
          let iconName = 'home';

          if (route.name === 'Dashboard') {
            iconName = 'dashboard';
          } else if (route.name === 'Lanes') {
            iconName = 'router';
          } else if (route.name === 'Submit') {
            iconName = 'add-circle';
          } else if (route.name === 'Settings') {
            iconName = 'settings';
          }

          return <Icon name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#007AFF',
        tabBarInactiveTintColor: '#8E8E93',
        headerTintColor: state.isOnline ? '#34C759' : '#FF3B30'
      })}
    >
      <Tab.Screen
        name="Dashboard"
        component={DashboardScreen}
        options={{ title: 'Omega OS' }}
      />
      <Tab.Screen
        name="Lanes"
        component={LanesScreen}
        options={{ title: 'Lane Details' }}
      />
      <Tab.Screen
        name="Submit"
        component={SubmitTaskScreen}
        options={{ title: 'Submit Task' }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsScreen}
        options={{ title: 'Settings' }}
      />
    </Tab.Navigator>
  );
}

function App(): React.JSX.Element {
  const { state, setError } = useAppState();
  const navigationRef = useRef(null);

  // Initialize WebSocket and notifications
  useEffect(() => {
    const initializeApp = async () => {
      try {
        // Initialize notifications
        await notificationService.initialize();

        // Connect to WebSocket
        const ws = getWebSocketClient(state.preferences?.serverUrl);

        ws.on('proof', (proof) => {
          // Handle new proof
          StorageService.addProof(proof);

          // If app is in foreground and current lane matches, update UI
          if (state.currentLane === proof.routed_lane) {
            console.log('[App] New proof for current lane:', proof.task_id);
          }
        });

        ws.on('error', (error) => {
          setError(String(error));
          console.error('[App] WebSocket error:', error);
        });

        // Only connect if we have a valid server URL
        if (state.preferences?.serverUrl) {
          await ws.connect();
        }
      } catch (error) {
        setError(String(error));
        console.error('[App] Initialization error:', error);
      }
    };

    if (!state.isLoadingPreferences && state.preferences) {
      initializeApp();
    }

    return () => {
      const ws = getWebSocketClient();
      // Don't disconnect here, maintain connection across screen changes
    };
  }, [state.preferences, state.isLoadingPreferences]);

  if (state.isLoadingPreferences) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={{ marginTop: 12, color: '#666' }}>Loading...</Text>
      </View>
    );
  }

  return (
    <>
      <StatusBar barStyle="dark-content" backgroundColor="#F2F2F7" />
      <NavigationContainer ref={navigationRef}>
        <Stack.Navigator
          screenOptions={{
            headerShown: false,
            animationEnabled: true
          }}
        >
          <Stack.Screen
            name="Main"
            component={DashboardTabs}
            options={{ animationEnabled: false }}
          />
        </Stack.Navigator>
      </NavigationContainer>

      {/* Connection Status Indicator */}
      {state.error && (
        <View
          style={{
            position: 'absolute',
            bottom: 80,
            left: 16,
            right: 16,
            backgroundColor: '#FF3B30',
            padding: 12,
            borderRadius: 8,
            flexDirection: 'row',
            alignItems: 'center'
          }}
        >
          <Icon name="error" size={18} color="white" />
          <Text style={{ color: 'white', marginLeft: 8, flex: 1 }}>
            {state.error}
          </Text>
        </View>
      )}
    </>
  );
}

export default App;
