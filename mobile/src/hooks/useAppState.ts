/**
 * Custom Hook: useAppState
 * Manages application global state and context
 */

import { useReducer, useCallback, useEffect } from 'react';
import { AppContextType } from '@types/index';
import { StorageService, UserPreferences } from '@services/storage';
import { ConnectionState, getWebSocketClient } from '@services/websocket';

interface AppState {
  isOnline: boolean;
  connectionState: ConnectionState;
  serverUrl: string;
  theme: 'light' | 'dark' | 'auto';
  currentLane: string | null;
  preferences: UserPreferences | null;
  isLoadingPreferences: boolean;
  error: string | null;
}

type AppAction =
  | { type: 'SET_ONLINE'; payload: boolean }
  | { type: 'SET_CONNECTION_STATE'; payload: ConnectionState }
  | { type: 'SET_SERVER_URL'; payload: string }
  | { type: 'SET_THEME'; payload: 'light' | 'dark' | 'auto' }
  | { type: 'SET_CURRENT_LANE'; payload: string | null }
  | { type: 'SET_PREFERENCES'; payload: UserPreferences }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'RESET' };

const initialState: AppState = {
  isOnline: false,
  connectionState: ConnectionState.DISCONNECTED,
  serverUrl: 'ws://localhost:8765',
  theme: 'auto',
  currentLane: null,
  preferences: null,
  isLoadingPreferences: true,
  error: null
};

function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_ONLINE':
      return { ...state, isOnline: action.payload };
    case 'SET_CONNECTION_STATE':
      return {
        ...state,
        connectionState: action.payload,
        isOnline: action.payload === ConnectionState.CONNECTED
      };
    case 'SET_SERVER_URL':
      return { ...state, serverUrl: action.payload };
    case 'SET_THEME':
      return { ...state, theme: action.payload };
    case 'SET_CURRENT_LANE':
      return { ...state, currentLane: action.payload };
    case 'SET_PREFERENCES':
      return { ...state, preferences: action.payload };
    case 'SET_LOADING':
      return { ...state, isLoadingPreferences: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload };
    case 'RESET':
      return initialState;
    default:
      return state;
  }
}

export function useAppState() {
  const [state, dispatch] = useReducer(appReducer, initialState);

  // Load preferences on mount
  useEffect(() => {
    const loadPreferences = async () => {
      try {
        const prefs = await StorageService.getPreferences();
        dispatch({ type: 'SET_PREFERENCES', payload: prefs });
        dispatch({ type: 'SET_SERVER_URL', payload: prefs.serverUrl });
        dispatch({ type: 'SET_THEME', payload: prefs.theme });
      } catch (error) {
        dispatch({ type: 'SET_ERROR', payload: String(error) });
      } finally {
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    };

    loadPreferences();
  }, []);

  // Monitor WebSocket connection
  useEffect(() => {
    const ws = getWebSocketClient();

    const handleStateChange = (newState: ConnectionState) => {
      dispatch({ type: 'SET_CONNECTION_STATE', payload: newState });
    };

    ws.on('stateChange', handleStateChange);

    return () => {
      ws.off('stateChange', handleStateChange);
    };
  }, []);

  const setOnline = useCallback((isOnline: boolean) => {
    dispatch({ type: 'SET_ONLINE', payload: isOnline });
  }, []);

  const setServerUrl = useCallback(async (url: string) => {
    dispatch({ type: 'SET_SERVER_URL', payload: url });
    await StorageService.savePreferences({ serverUrl: url });
  }, []);

  const setTheme = useCallback(async (theme: 'light' | 'dark' | 'auto') => {
    dispatch({ type: 'SET_THEME', payload: theme });
    await StorageService.savePreferences({ theme });
  }, []);

  const setCurrentLane = useCallback((lane: string | null) => {
    dispatch({ type: 'SET_CURRENT_LANE', payload: lane });
  }, []);

  const setError = useCallback((error: string | null) => {
    dispatch({ type: 'SET_ERROR', payload: error });
  }, []);

  return {
    state,
    setOnline,
    setServerUrl,
    setTheme,
    setCurrentLane,
    setError
  };
}
