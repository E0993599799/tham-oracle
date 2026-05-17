/**
 * 6E: Notification Handler Service
 * Manages push notifications (APNS/FCM) and local notifications
 * Handles notification permissions and delivery
 */

import messaging from '@react-native-firebase/messaging';
import { Platform } from 'react-native';

export interface NotificationPayload {
  task_id: string;
  lane: string;
  status: string;
  duration: number;
  timestamp: string;
}

export class NotificationService {
  private static instance: NotificationService;
  private notificationHandler: ((payload: NotificationPayload) => void) | null = null;
  private isInitialized = false;

  private constructor() {}

  static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      // Request permission
      const authStatus = await messaging().requestPermission();
      const enabled =
        authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
        authStatus === messaging.AuthorizationStatus.PROVISIONAL;

      if (enabled) {
        console.log('[Notifications] Authorization status:', authStatus);

        // Get FCM token
        const token = await messaging().getToken();
        console.log('[Notifications] FCM Token:', token);

        // Handle foreground messages
        messaging().onMessage(async (remoteMessage) => {
          console.log('[Notifications] Foreground message:', remoteMessage);
          this.handleNotification(remoteMessage);
        });

        // Handle background messages
        messaging().setBackgroundMessageHandler(async (remoteMessage) => {
          console.log('[Notifications] Background message:', remoteMessage);
          this.handleNotification(remoteMessage);
        });

        this.isInitialized = true;
      } else {
        console.log('[Notifications] Notification permission denied');
      }
    } catch (error) {
      console.error('[Notifications] Initialization error:', error);
    }
  }

  private handleNotification(remoteMessage: any): void {
    try {
      const payload: NotificationPayload = {
        task_id: remoteMessage.data?.task_id || 'unknown',
        lane: remoteMessage.data?.lane || 'unknown',
        status: remoteMessage.data?.status || 'UNKNOWN',
        duration: parseFloat(remoteMessage.data?.duration || '0'),
        timestamp: remoteMessage.data?.timestamp || new Date().toISOString()
      };

      if (this.notificationHandler) {
        this.notificationHandler(payload);
      }
    } catch (error) {
      console.error('[Notifications] Error handling notification:', error);
    }
  }

  setNotificationHandler(handler: (payload: NotificationPayload) => void): void {
    this.notificationHandler = handler;
  }

  async isNotificationEnabled(lane?: string): Promise<boolean> {
    try {
      const authStatus = await messaging().hasPermission();
      return (
        authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
        authStatus === messaging.AuthorizationStatus.PROVISIONAL
      );
    } catch (error) {
      console.error('[Notifications] Error checking permission:', error);
      return false;
    }
  }

  async subscribeToTopic(topic: string): Promise<void> {
    try {
      await messaging().subscribeToTopic(topic);
      console.log(`[Notifications] Subscribed to topic: ${topic}`);
    } catch (error) {
      console.error(`[Notifications] Error subscribing to topic ${topic}:`, error);
    }
  }

  async unsubscribeFromTopic(topic: string): Promise<void> {
    try {
      await messaging().unsubscribeFromTopic(topic);
      console.log(`[Notifications] Unsubscribed from topic: ${topic}`);
    } catch (error) {
      console.error(`[Notifications] Error unsubscribing from topic ${topic}:`, error);
    }
  }

  async subscribeToLaneNotifications(lanes: string[]): Promise<void> {
    try {
      for (const lane of lanes) {
        await this.subscribeToTopic(`lane_${lane}`);
      }
    } catch (error) {
      console.error('[Notifications] Error subscribing to lanes:', error);
    }
  }

  async getFCMToken(): Promise<string | null> {
    try {
      return await messaging().getToken();
    } catch (error) {
      console.error('[Notifications] Error getting FCM token:', error);
      return null;
    }
  }
}

export const notificationService = NotificationService.getInstance();
