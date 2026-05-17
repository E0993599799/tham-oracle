/**
 * 6G: Storage Service
 * Local data persistence using AsyncStorage
 * Caches proofs, stats, and user preferences
 */

import AsyncStorage from '@react-native-async-storage/async-storage';
import { Proof } from './websocket';

export interface UserPreferences {
  serverUrl: string;
  theme: 'light' | 'dark' | 'auto';
  notificationsEnabled: boolean;
  notificationsByLane: { [lane: string]: boolean };
  autoRefreshInterval: number; // seconds
  graphResolution: 'hourly' | '6hourly' | 'daily';
}

export interface CachedStats {
  timestamp: number;
  totalTasks: number;
  successRate: number;
  avgDuration: number;
  byLane: {
    [lane: string]: {
      count: number;
      successRate: number;
      avgDuration: number;
    };
  };
}

const STORAGE_KEYS = {
  PROOFS: 'omega_proofs',
  STATS: 'omega_stats',
  PREFERENCES: 'omega_preferences',
  SYNC_TIME: 'omega_sync_time'
};

const DEFAULT_PREFERENCES: UserPreferences = {
  serverUrl: 'ws://localhost:8765',
  theme: 'auto',
  notificationsEnabled: true,
  notificationsByLane: {},
  autoRefreshInterval: 10,
  graphResolution: 'hourly'
};

export class StorageService {
  static async saveProofs(proofs: Proof[]): Promise<void> {
    try {
      // Keep only last 1000 proofs
      const limited = proofs.slice(-1000);
      await AsyncStorage.setItem(STORAGE_KEYS.PROOFS, JSON.stringify(limited));
    } catch (error) {
      console.error('[Storage] Error saving proofs:', error);
    }
  }

  static async getProofs(): Promise<Proof[]> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.PROOFS);
      return data ? JSON.parse(data) : [];
    } catch (error) {
      console.error('[Storage] Error loading proofs:', error);
      return [];
    }
  }

  static async addProof(proof: Proof): Promise<void> {
    try {
      const proofs = await this.getProofs();
      proofs.push(proof);
      await this.saveProofs(proofs);
    } catch (error) {
      console.error('[Storage] Error adding proof:', error);
    }
  }

  static async getProofsByLane(lane: string): Promise<Proof[]> {
    try {
      const proofs = await this.getProofs();
      return proofs.filter(p => p.rooted_lane === lane);
    } catch (error) {
      console.error('[Storage] Error filtering proofs:', error);
      return [];
    }
  }

  static async getProofsInTimeRange(
    startTime: number,
    endTime: number
  ): Promise<Proof[]> {
    try {
      const proofs = await this.getProofs();
      return proofs.filter(p => {
        const timestamp = new Date(p.timestamp).getTime();
        return timestamp >= startTime && timestamp <= endTime;
      });
    } catch (error) {
      console.error('[Storage] Error getting proofs in range:', error);
      return [];
    }
  }

  static async saveStats(stats: CachedStats): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.STATS, JSON.stringify(stats));
    } catch (error) {
      console.error('[Storage] Error saving stats:', error);
    }
  }

  static async getStats(maxAge: number = 300000): Promise<CachedStats | null> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.STATS);
      if (!data) return null;

      const stats: CachedStats = JSON.parse(data);
      const age = Date.now() - stats.timestamp;

      if (age > maxAge) return null; // Cache expired
      return stats;
    } catch (error) {
      console.error('[Storage] Error loading stats:', error);
      return null;
    }
  }

  static async savePreferences(prefs: Partial<UserPreferences>): Promise<void> {
    try {
      const existing = await this.getPreferences();
      const merged = { ...existing, ...prefs };
      await AsyncStorage.setItem(STORAGE_KEYS.PREFERENCES, JSON.stringify(merged));
    } catch (error) {
      console.error('[Storage] Error saving preferences:', error);
    }
  }

  static async getPreferences(): Promise<UserPreferences> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.PREFERENCES);
      return data ? { ...DEFAULT_PREFERENCES, ...JSON.parse(data) } : DEFAULT_PREFERENCES;
    } catch (error) {
      console.error('[Storage] Error loading preferences:', error);
      return DEFAULT_PREFERENCES;
    }
  }

  static async clearCache(): Promise<void> {
    try {
      await AsyncStorage.removeItem(STORAGE_KEYS.PROOFS);
      await AsyncStorage.removeItem(STORAGE_KEYS.STATS);
      await AsyncStorage.removeItem(STORAGE_KEYS.SYNC_TIME);
    } catch (error) {
      console.error('[Storage] Error clearing cache:', error);
    }
  }

  static async getCacheSize(): Promise<number> {
    try {
      const proofs = await this.getProofs();
      const stats = await AsyncStorage.getItem(STORAGE_KEYS.STATS);
      const proofSize = JSON.stringify(proofs).length;
      const statsSize = stats ? stats.length : 0;
      return proofSize + statsSize;
    } catch (error) {
      console.error('[Storage] Error calculating cache size:', error);
      return 0;
    }
  }

  static async setSyncTime(): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.SYNC_TIME, Date.now().toString());
    } catch (error) {
      console.error('[Storage] Error setting sync time:', error);
    }
  }

  static async getLastSyncTime(): Promise<number | null> {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.SYNC_TIME);
      return data ? parseInt(data, 10) : null;
    } catch (error) {
      console.error('[Storage] Error getting sync time:', error);
      return null;
    }
  }
}
