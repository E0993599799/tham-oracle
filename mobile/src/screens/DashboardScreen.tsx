/**
 * 6B: Dashboard Screen
 * Main dashboard with overall stats and lane status cards
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  Dimensions
} from 'react-native';
import { ProgressBar } from '@react-native-community/progress-bar-android';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { getWebSocketClient } from '@services/websocket';
import { StorageService } from '@services/storage';
import { Proof } from '@services/websocket';
import { DashboardStats, Lane } from '@types/index';

const LANES = [
  'codex_gpt55',
  'claude',
  'gemini',
  'ollama',
  'hermes',
  'powershell_sfsr'
];

function DashboardScreen(): React.JSX.Element {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [proofs, setProofs] = useState<Proof[]>([]);

  useEffect(() => {
    loadDashboardData();

    // Listen for new proofs
    const ws = getWebSocketClient();
    const handleProof = (proof: Proof) => {
      setProofs((prev) => [proof, ...prev].slice(0, 10));
      loadDashboardData();
    };

    ws.on('proof', handleProof);
    return () => {
      ws.off('proof', handleProof);
    };
  }, []);

  async function loadDashboardData() {
    try {
      const allProofs = await StorageService.getProofs();
      setProofs(allProofs.slice(-10).reverse());

      // Calculate stats
      const stats = calculateStats(allProofs);
      setStats(stats);
    } catch (error) {
      console.error('[Dashboard] Error loading data:', error);
    }
  }

  function calculateStats(allProofs: Proof[]): DashboardStats {
    const laneStats: { [key: string]: { count: number; success: number; durations: number[] } } = {};

    // Initialize lane stats
    LANES.forEach((lane) => {
      laneStats[lane] = { count: 0, success: 0, durations: [] };
    });

    // Process proofs
    allProofs.forEach((proof) => {
      const lane = proof.routed_lane;
      if (laneStats[lane]) {
        laneStats[lane].count++;
        if (proof.status === 'SUCCESS') {
          laneStats[lane].success++;
        }
        laneStats[lane].durations.push(proof.execution_duration_seconds);
      }
    });

    // Calculate aggregates
    let totalSuccess = 0;
    let totalDurations = 0;
    const lanes: Lane[] = LANES.map((laneId) => {
      const ls = laneStats[laneId];
      const successRate = ls.count > 0 ? (ls.success / ls.count) * 100 : 0;
      const avgDuration = ls.durations.length > 0
        ? ls.durations.reduce((a, b) => a + b, 0) / ls.durations.length
        : 0;

      totalSuccess += ls.success;
      totalDurations += totalSuccess;

      return {
        id: laneId,
        name: laneId,
        status: successRate >= 80 ? 'healthy' : successRate >= 50 ? 'degraded' : 'down',
        taskCount: ls.count,
        successRate,
        avgDuration,
        responseTime: ls.count > 0 ? Math.random() * 1000 : 0, // Mock
        lastUpdate: new Date().toISOString()
      };
    });

    const overallSuccessRate = allProofs.length > 0
      ? (totalSuccess / allProofs.length) * 100
      : 0;
    const avgDuration = allProofs.length > 0
      ? allProofs.reduce((acc, p) => acc + p.execution_duration_seconds, 0) / allProofs.length
      : 0;

    return {
      totalTasks: allProofs.length,
      successRate: overallSuccessRate,
      avgDuration,
      lastUpdate: new Date().toISOString(),
      lanes
    };
  }

  const onRefresh = React.useCallback(() => {
    setRefreshing(true);
    loadDashboardData().finally(() => setRefreshing(false));
  }, []);

  if (!stats) {
    return (
      <View style={styles.container}>
        <Text>Loading...</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
    >
      {/* Overall Stats */}
      <View style={styles.statsCard}>
        <Text style={styles.cardTitle}>Overall Stats</Text>
        <View style={styles.statRow}>
          <View style={styles.statItem}>
            <Text style={styles.statLabel}>Total Tasks</Text>
            <Text style={styles.statValue}>{stats.totalTasks}</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statLabel}>Success Rate</Text>
            <Text style={styles.statValue}>{stats.successRate.toFixed(1)}%</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statLabel}>Avg Duration</Text>
            <Text style={styles.statValue}>{stats.avgDuration.toFixed(2)}s</Text>
          </View>
        </View>

        {/* Success Rate Progress Bar */}
        <View style={styles.progressContainer}>
          <Text style={styles.progressLabel}>Success Rate</Text>
          <View
            style={[
              styles.progressBar,
              { backgroundColor: getProgressColor(stats.successRate) }
            ]}
          >
            <Text style={styles.progressText}>{stats.successRate.toFixed(0)}%</Text>
          </View>
        </View>
      </View>

      {/* Lane Status Cards */}
      <Text style={styles.sectionTitle}>Lane Status</Text>
      <View style={styles.laneGrid}>
        {stats.lanes.map((lane) => (
          <View key={lane.id} style={styles.laneCard}>
            <View style={styles.laneHeader}>
              <Text style={styles.laneStatusEmoji}>
                {lane.status === 'healthy'
                  ? '🟢'
                  : lane.status === 'degraded'
                  ? '🟡'
                  : lane.taskCount === 0
                  ? '⚪'
                  : '🔴'}
              </Text>
              <Text style={styles.laneName}>{lane.id.substring(0, 8)}</Text>
            </View>
            <View style={styles.laneStats}>
              <Text style={styles.laneStat}>{lane.taskCount} tasks</Text>
              <Text style={styles.laneStat}>{lane.successRate.toFixed(0)}%</Text>
            </View>
          </View>
        ))}
      </View>

      {/* Recent Proofs */}
      <Text style={styles.sectionTitle}>Recent Proofs</Text>
      {proofs.map((proof, index) => (
        <View key={index} style={styles.proofItem}>
          <Text style={styles.proofEmoji}>
            {proof.status === 'SUCCESS' ? '✓' : '✗'}
          </Text>
          <View style={styles.proofInfo}>
            <Text style={styles.proofId}>{proof.task_id.substring(0, 20)}</Text>
            <Text style={styles.proofLane}>{proof.routed_lane}</Text>
          </View>
          <Text style={styles.proofDuration}>{proof.execution_duration_seconds.toFixed(2)}s</Text>
        </View>
      ))}

      <View style={styles.spacer} />
    </ScrollView>
  );
}

function getProgressColor(percentage: number): string {
  if (percentage >= 80) return '#34C759';
  if (percentage >= 50) return '#FFCC00';
  return '#FF3B30';
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
    padding: 16
  },
  statsCard: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12
  },
  statRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16
  },
  statItem: {
    flex: 1,
    alignItems: 'center'
  },
  statLabel: {
    fontSize: 12,
    color: '#8E8E93',
    marginBottom: 4
  },
  statValue: {
    fontSize: 20,
    fontWeight: '700',
    color: '#007AFF'
  },
  progressContainer: {
    marginTop: 16
  },
  progressLabel: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8
  },
  progressBar: {
    height: 24,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center'
  },
  progressText: {
    color: 'white',
    fontWeight: '600',
    fontSize: 12
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 12,
    marginTop: 8
  },
  laneGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: 20
  },
  laneCard: {
    width: '48%',
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2
  },
  laneHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8
  },
  laneStatusEmoji: {
    fontSize: 20,
    marginRight: 8
  },
  laneName: {
    fontSize: 12,
    fontWeight: '600',
    color: '#333'
  },
  laneStats: {
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  laneStat: {
    fontSize: 11,
    color: '#8E8E93'
  },
  proofItem: {
    flexDirection: 'row',
    backgroundColor: 'white',
    padding: 12,
    marginBottom: 8,
    borderRadius: 8,
    alignItems: 'center'
  },
  proofEmoji: {
    fontSize: 18,
    marginRight: 12
  },
  proofInfo: {
    flex: 1
  },
  proofId: {
    fontSize: 12,
    fontWeight: '500',
    color: '#333'
  },
  proofLane: {
    fontSize: 11,
    color: '#8E8E93'
  },
  proofDuration: {
    fontSize: 11,
    color: '#666',
    fontWeight: '500'
  },
  spacer: {
    height: 40
  }
});

export default DashboardScreen;
