/**
 * 6C: Lanes Detail Screen
 * Detailed per-lane view with history and trends
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Picker,
  Dimensions
} from 'react-native';
import { LineChart } from 'react-native-chart-kit';
import { StorageService } from '@services/storage';
import { Proof } from '@services/websocket';
import { Lane } from '@types/index';

const LANES = [
  'codex_gpt55',
  'claude',
  'gemini',
  'ollama',
  'hermes',
  'powershell_sfsr'
];

function LanesScreen(): React.JSX.Element {
  const [selectedLane, setSelectedLane] = useState('codex_gpt55');
  const [laneData, setLaneData] = useState<Lane | null>(null);
  const [successHistory, setSuccessHistory] = useState<any>(null);
  const [responseTimeHistory, setResponseTimeHistory] = useState<any>(null);
  const [laneProofs, setLaneProofs] = useState<Proof[]>([]);

  useEffect(() => {
    loadLaneData();
  }, [selectedLane]);

  async function loadLaneData() {
    try {
      const allProofs = await StorageService.getProofs();
      const proofs = allProofs.filter((p) => p.routed_lane === selectedLane);

      // Calculate lane stats
      const totalCount = proofs.length;
      const successCount = proofs.filter((p) => p.status === 'SUCCESS').length;
      const successRate = totalCount > 0 ? (successCount / totalCount) * 100 : 0;
      const avgDuration =
        proofs.length > 0
          ? proofs.reduce((sum, p) => sum + p.execution_duration_seconds, 0) / proofs.length
          : 0;

      setLaneData({
        id: selectedLane,
        name: selectedLane,
        status: successRate >= 80 ? 'healthy' : successRate >= 50 ? 'degraded' : 'down',
        taskCount: totalCount,
        successRate,
        avgDuration,
        responseTime: Math.random() * 1000,
        lastUpdate: new Date().toISOString()
      });

      // Calculate history (24 hours)
      const now = Date.now();
      const hourlyStats: { [key: number]: { success: number; total: number; durations: number[] } } = {};

      for (let i = 0; i < 24; i++) {
        hourlyStats[i] = { success: 0, total: 0, durations: [] };
      }

      proofs.forEach((proof) => {
        const proofTime = new Date(proof.timestamp).getTime();
        const hourDiff = Math.floor((now - proofTime) / (1000 * 60 * 60));
        if (hourDiff >= 0 && hourDiff < 24) {
          hourlyStats[hourDiff].total++;
          if (proof.status === 'SUCCESS') {
            hourlyStats[hourDiff].success++;
          }
          hourlyStats[hourDiff].durations.push(proof.execution_duration_seconds);
        }
      });

      // Build chart data
      const successLabels: string[] = [];
      const successData: number[] = [];
      const responseTimeLabels: string[] = [];
      const responseTimeData: number[] = [];

      for (let i = 23; i >= 0; i -= 2) {
        const stats = hourlyStats[i];
        const successPct = stats.total > 0 ? (stats.success / stats.total) * 100 : 0;
        const avgResponseTime = stats.durations.length > 0
          ? stats.durations.reduce((a, b) => a + b, 0) / stats.durations.length
          : 0;

        successLabels.push(`${i}h`);
        successData.push(successPct);
        responseTimeLabels.push(`${i}h`);
        responseTimeData.push(avgResponseTime);
      }

      setSuccessHistory({
        labels: successLabels,
        datasets: [
          {
            data: successData,
            color: () => '#34C759',
            strokeWidth: 2
          }
        ]
      });

      setResponseTimeHistory({
        labels: responseTimeLabels,
        datasets: [
          {
            data: responseTimeData,
            color: () => '#007AFF',
            strokeWidth: 2
          }
        ]
      });

      setLaneProofs(proofs.slice(-5).reverse());
    } catch (error) {
      console.error('[Lanes] Error loading data:', error);
    }
  }

  if (!laneData) {
    return <Text>Loading...</Text>;
  }

  const screenWidth = Dimensions.get('window').width - 32;

  return (
    <ScrollView style={styles.container}>
      {/* Lane Selector */}
      <View style={styles.selectorContainer}>
        <Text style={styles.label}>Select Lane</Text>
        <Picker
          selectedValue={selectedLane}
          onValueChange={setSelectedLane}
          style={styles.picker}
        >
          {LANES.map((lane) => (
            <Picker.Item key={lane} label={lane} value={lane} />
          ))}
        </Picker>
      </View>

      {/* Lane Status */}
      <View style={styles.statusCard}>
        <Text style={styles.statusEmoji}>
          {laneData.status === 'healthy'
            ? '🟢'
            : laneData.status === 'degraded'
            ? '🟡'
            : '🔴'}
        </Text>
        <View style={styles.statusInfo}>
          <Text style={styles.laneName}>{laneData.name}</Text>
          <Text style={styles.statusText}>
            {laneData.status === 'healthy'
              ? 'Healthy'
              : laneData.status === 'degraded'
              ? 'Degraded'
              : 'Down'}
          </Text>
        </View>
        <View style={styles.statusStats}>
          <Text style={styles.statSmall}>{laneData.taskCount} tasks</Text>
          <Text style={styles.statSmall}>{laneData.successRate.toFixed(0)}%</Text>
        </View>
      </View>

      {/* Success Rate Trend */}
      {successHistory && (
        <View style={styles.chartCard}>
          <Text style={styles.chartTitle}>Success Rate (24h)</Text>
          <LineChart
            data={successHistory}
            width={screenWidth}
            height={220}
            chartConfig={{
              backgroundColor: '#ffffff',
              backgroundGradientFrom: '#ffffff',
              backgroundGradientTo: '#ffffff',
              color: () => '#34C759',
              strokeWidth: 2,
              propsForDots: {
                r: '4',
                strokeWidth: '2',
                stroke: '#34C759'
              }
            }}
            withVerticalLabels={true}
            withHorizontalLabels={true}
          />
        </View>
      )}

      {/* Response Time Trend */}
      {responseTimeHistory && (
        <View style={styles.chartCard}>
          <Text style={styles.chartTitle}>Response Time (24h)</Text>
          <LineChart
            data={responseTimeHistory}
            width={screenWidth}
            height={220}
            chartConfig={{
              backgroundColor: '#ffffff',
              backgroundGradientFrom: '#ffffff',
              backgroundGradientTo: '#ffffff',
              color: () => '#007AFF',
              strokeWidth: 2,
              propsForDots: {
                r: '4',
                strokeWidth: '2',
                stroke: '#007AFF'
              }
            }}
            withVerticalLabels={true}
            withHorizontalLabels={true}
          />
        </View>
      )}

      {/* Recent Proofs for This Lane */}
      <Text style={styles.sectionTitle}>Recent Proofs</Text>
      {laneProofs.map((proof, index) => (
        <View key={index} style={styles.proofItem}>
          <Text style={styles.proofEmoji}>
            {proof.status === 'SUCCESS' ? '✓' : '✗'}
          </Text>
          <View style={styles.proofDetails}>
            <Text style={styles.proofId}>{proof.task_id}</Text>
            <Text style={styles.proofStatus}>{proof.status}</Text>
          </View>
          <Text style={styles.proofDuration}>{proof.execution_duration_seconds.toFixed(2)}s</Text>
        </View>
      ))}

      <View style={styles.spacer} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
    padding: 16
  },
  selectorContainer: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333'
  },
  picker: {
    height: 40,
    backgroundColor: '#F2F2F7'
  },
  statusCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16
  },
  statusEmoji: {
    fontSize: 32,
    marginRight: 12
  },
  statusInfo: {
    flex: 1
  },
  laneName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333'
  },
  statusText: {
    fontSize: 12,
    color: '#8E8E93'
  },
  statusStats: {
    alignItems: 'flex-end'
  },
  statSmall: {
    fontSize: 12,
    color: '#666',
    fontWeight: '500'
  },
  chartCard: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16
  },
  chartTitle: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 12,
    color: '#333'
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 12,
    marginTop: 8,
    color: '#333'
  },
  proofItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'white',
    padding: 12,
    marginBottom: 8,
    borderRadius: 8
  },
  proofEmoji: {
    fontSize: 18,
    marginRight: 12
  },
  proofDetails: {
    flex: 1
  },
  proofId: {
    fontSize: 12,
    fontWeight: '500',
    color: '#333'
  },
  proofStatus: {
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

export default LanesScreen;
