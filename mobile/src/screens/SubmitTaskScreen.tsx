/**
 * 6D: Submit Task Screen
 * Remote task submission UI
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  Picker
} from 'react-native';
import axios from 'axios';
import { StorageService } from '@services/storage';
import { TaskSubmission, TaskResult } from '@types/index';

const INTENTS = [
  'write_code',
  'fix_bug',
  'review',
  'design',
  'search',
  'summarize',
  'patch',
  'refactor',
  'security_audit'
];

const QUICK_TASKS = [
  { label: '📝 Code Review', intent: 'review', context: 'Review the following code for issues and improvements' },
  { label: '🐛 Fix Bug', intent: 'fix_bug', context: 'Fix the bug in the following code' },
  { label: '✍️ Write Code', intent: 'write_code', context: 'Write code to implement the following requirement' },
  { label: '🔍 Search', intent: 'search', context: 'Search for information about' },
  { label: '📊 Summarize', intent: 'summarize', context: 'Summarize the following content' }
];

function SubmitTaskScreen(): React.JSX.Element {
  const [selectedIntent, setSelectedIntent] = useState('write_code');
  const [context, setContext] = useState('');
  const [riskLevel, setRiskLevel] = useState<'low' | 'medium' | 'high' | 'critical'>('medium');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<TaskResult | null>(null);
  const [submittedTasks, setSubmittedTasks] = useState<TaskResult[]>([]);

  const handleSubmitTask = async () => {
    if (!context.trim()) {
      Alert.alert('Error', 'Please enter task context');
      return;
    }

    setLoading(true);
    try {
      // In a real app, this would call the Telegram bot API
      // For now, we'll create a local task contract
      const taskId = `task-${Date.now()}`;
      const result: TaskResult = {
        task_id: taskId,
        status: 'submitted',
        routed_lane: 'pending',
        message: 'Task submitted successfully'
      };

      setResult(result);
      setSubmittedTasks((prev) => [result, ...prev.slice(0, 9)]);

      // Reset form
      setContext('');

      Alert.alert('Success', `Task ${taskId} submitted!`);
    } catch (error) {
      Alert.alert('Error', String(error));
    } finally {
      setLoading(false);
    }
  };

  const handleQuickTask = (task: (typeof QUICK_TASKS)[0]) => {
    setSelectedIntent(task.intent);
    setContext(task.context);
  };

  return (
    <ScrollView style={styles.container}>
      {/* Quick Actions */}
      <Text style={styles.sectionTitle}>Quick Actions</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.quickTasksScroll}>
        {QUICK_TASKS.map((task) => (
          <TouchableOpacity
            key={task.intent}
            style={styles.quickTask}
            onPress={() => handleQuickTask(task)}
          >
            <Text style={styles.quickTaskLabel}>{task.label}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {/* Form */}
      <View style={styles.form}>
        {/* Intent Selector */}
        <View style={styles.formGroup}>
          <Text style={styles.label}>Intent Signal</Text>
          <Picker
            selectedValue={selectedIntent}
            onValueChange={setSelectedIntent}
            style={styles.picker}
          >
            {INTENTS.map((intent) => (
              <Picker.Item key={intent} label={intent} value={intent} />
            ))}
          </Picker>
        </View>

        {/* Context Input */}
        <View style={styles.formGroup}>
          <Text style={styles.label}>Task Context</Text>
          <TextInput
            style={styles.contextInput}
            placeholder="Describe what you want the task to do..."
            multiline
            numberOfLines={4}
            value={context}
            onChangeText={setContext}
            placeholderTextColor="#C7C7CC"
          />
        </View>

        {/* Risk Level */}
        <View style={styles.formGroup}>
          <Text style={styles.label}>Risk Level</Text>
          <Picker
            selectedValue={riskLevel}
            onValueChange={(value) => setRiskLevel(value as any)}
            style={styles.picker}
          >
            <Picker.Item label="Low" value="low" />
            <Picker.Item label="Medium" value="medium" />
            <Picker.Item label="High" value="high" />
            <Picker.Item label="Critical" value="critical" />
          </Picker>
        </View>

        {/* Submit Button */}
        <TouchableOpacity
          style={[styles.submitButton, loading && styles.submitButtonDisabled]}
          onPress={handleSubmitTask}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="white" />
          ) : (
            <Text style={styles.submitButtonText}>Submit Task</Text>
          )}
        </TouchableOpacity>
      </View>

      {/* Result */}
      {result && (
        <View style={styles.resultCard}>
          <Text style={styles.resultTitle}>✓ Task Submitted</Text>
          <Text style={styles.resultField}>
            <Text style={styles.resultLabel}>Task ID: </Text>
            <Text style={styles.resultValue}>{result.task_id}</Text>
          </Text>
          <Text style={styles.resultField}>
            <Text style={styles.resultLabel}>Status: </Text>
            <Text style={styles.resultValue}>{result.status}</Text>
          </Text>
          <Text style={styles.resultField}>
            <Text style={styles.resultLabel}>Lane: </Text>
            <Text style={styles.resultValue}>{result.routed_lane}</Text>
          </Text>
        </View>
      )}

      {/* Submitted Tasks History */}
      {submittedTasks.length > 0 && (
        <View style={styles.historyContainer}>
          <Text style={styles.sectionTitle}>Submitted Tasks</Text>
          {submittedTasks.map((task) => (
            <View key={task.task_id} style={styles.taskHistoryItem}>
              <View style={styles.taskHistoryInfo}>
                <Text style={styles.taskHistoryId}>{task.task_id}</Text>
                <Text style={styles.taskHistoryStatus}>{task.status}</Text>
              </View>
              <Text style={styles.taskHistoryLane}>{task.routed_lane}</Text>
            </View>
          ))}
        </View>
      )}

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
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 12,
    marginTop: 8,
    color: '#333'
  },
  quickTasksScroll: {
    marginBottom: 20
  },
  quickTask: {
    backgroundColor: 'white',
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 16,
    marginRight: 12,
    borderWidth: 1,
    borderColor: '#007AFF'
  },
  quickTaskLabel: {
    color: '#007AFF',
    fontWeight: '500',
    fontSize: 12
  },
  form: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20
  },
  formGroup: {
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
    backgroundColor: '#F2F2F7',
    borderRadius: 8
  },
  contextInput: {
    backgroundColor: '#F2F2F7',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    color: '#333',
    textAlignVertical: 'top',
    minHeight: 100
  },
  submitButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 12,
    alignItems: 'center',
    marginTop: 8
  },
  submitButtonDisabled: {
    opacity: 0.6
  },
  submitButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600'
  },
  resultCard: {
    backgroundColor: '#D1F4E0',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    borderLeftWidth: 4,
    borderLeftColor: '#34C759'
  },
  resultTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#34C759',
    marginBottom: 12
  },
  resultField: {
    fontSize: 12,
    marginBottom: 6
  },
  resultLabel: {
    fontWeight: '600',
    color: '#333'
  },
  resultValue: {
    color: '#555',
    fontFamily: 'monospace'
  },
  historyContainer: {
    marginBottom: 20
  },
  taskHistoryItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: 'white',
    padding: 12,
    marginBottom: 8,
    borderRadius: 8
  },
  taskHistoryInfo: {
    flex: 1
  },
  taskHistoryId: {
    fontSize: 12,
    fontWeight: '500',
    color: '#333'
  },
  taskHistoryStatus: {
    fontSize: 11,
    color: '#8E8E93'
  },
  taskHistoryLane: {
    fontSize: 11,
    color: '#666',
    fontWeight: '500'
  },
  spacer: {
    height: 40
  }
});

export default SubmitTaskScreen;
